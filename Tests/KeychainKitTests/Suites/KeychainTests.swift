
import Foundation
import Observation
import Testing

@testable import KeychainKit

@Suite
struct KeychainTests {

    private enum Constants {

        static let testAccount: String = "TestAccount"

        static let keychainItems: Array<any KeychainItemProtocol.Type> = {
            func read<ItemValue>(itemValue: ItemValue) -> ItemValue.Item.Type where ItemValue: KeychainItemValueProtocol {
                return ItemValue.Item.self
            }

            return Self.keychainItemValues.map { itemValue in
                return read(itemValue: itemValue)
            }
        }()

        static let keychainItemValues: Array<any KeychainItemValueProtocol> = [
            KeychainItemValue<TestDataKeychainItem>(value: Data("Bar".utf8)),
            KeychainItemValue<TestStringKeychainItem>(value: "Bar"),
            KeychainItemValue<TestOptionalDataKeychainItem>(value: Data("Bar".utf8)),
            KeychainItemValue<TestOptionalStringKeychainItem>(value: "Bar"),
        ]
    }

    @Test(arguments: Constants.keychainItems)
    func testEmpty_Read_ReturnsDefaultValue(_ item: any KeychainItemProtocol.Type) async throws {
        func projection<Item>(_ item: Item.Type) async throws where Item: KeychainItemProtocol {
            try await withKeychain { keychain in
                let initialValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                #expect(initialValue == Item.defaultValue)
            }
        }

        try await projection(item)
    }

    @Test(arguments: Constants.keychainItemValues)
    func testEmpty_Read_Update_Read_Remove_ReturnsDefaultValue(_ itemValue: any KeychainItemValueProtocol) async throws {
        func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
            try await withKeychain { keychain in
                let initialValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                #expect(initialValue == Item.defaultValue)

                try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)

                let updatedValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                #expect(updatedValue == value)

                try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)

                let removedValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                #expect(removedValue == Item.defaultValue)
            }
        }

        func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
            try await projection(ItemValue.Item.self, value: itemValue.value)
        }

        try await unwrap(itemValue)
    }

    @Test
    func testReadInvalidRepresentableValue_ThrowsDecodingError() async throws {
        try await withKeychain(initialStorage: [
            KeychainQuery(accessGroup: nil, account: Constants.testAccount, service: TestInvalidKeychainRepresentableKeychainItem.service): Data()
        ]) { keychain in
            let thrownError = #expect(throws: KeychainError.self) {
                try keychain.value(forItem: TestInvalidKeychainRepresentableKeychainItem.self, account: Constants.testAccount)
            }

            guard case .decodingError = try #require(thrownError) else {
                Issue.record("Expected .decodingError, received \(String(describing: thrownError))")
                return
            }
        }
    }

    @Test
    func testUpdateInvalidRepresentableValue_ThrowsEncodingError() async throws {
        try await withKeychain { keychain in
            let thrownError = #expect(throws: KeychainError.self) {
                try keychain.updateValue(TestInvalidKeychainRepresentable(), forItem: TestInvalidKeychainRepresentableKeychainItem.self, account: Constants.testAccount)
            }

            guard case .encodingError = try #require(thrownError) else {
                Issue.record("Expected .encodingError, received \(String(describing: thrownError))")
                return
            }
        }
    }

    @Suite
    struct ObservationTests {

        @Test(arguments: Constants.keychainItems)
        func testEmpty_Update_Read_Remove_Observes(_ item: any KeychainItemProtocol.Type) async throws {
            func projection<Item>(_ item: Item.Type) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try keychain.updateValue(Item.defaultValue, forItem: Item.self, account: Constants.testAccount)

                    try await confirmation { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                    }
                }
            }

            try await projection(item)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_Empty_Read_Update_Observes(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)
                    }

                    try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_Update_DoesNotObserve(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation(expectedCount: 0) { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)
                    }

                    try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_Remove_DoesNotObserve(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation(expectedCount: 0) { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)
                    }

                    try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_Update_ReadWithinChange_ReturnsPreviousValue(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)

                    try await confirmation { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            #expect(throws: Never.self) {
                                let currentValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                                #expect(currentValue == value)
                            }
                            confirmation()
                        })

                        try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                    }
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_Update_RemoveWithinChange_PreservesOuterValue(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation { confirmation in
                        withObservationTrackingOnce({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, willSet: {
                            #expect(throws: Never.self) {
                                try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                            }
                            confirmation()
                        })

                        try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)

                        let updatedValue = try keychain.value(forItem: Item.self, account: Constants.testAccount)
                        #expect(updatedValue == value)
                    }

                    try keychain.removeValue(forItem: Item.self, account: Constants.testAccount)
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_OtherAccount_DoesNotObserve(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation(expectedCount: 0) { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        try keychain.updateValue(value, forItem: Item.self, account: "OtherAccount")
                    }
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }

        @Test
        func testObservation_SharedService_Observes() async throws {
            enum TestAliasedStringKeychainItem: KeychainItemProtocol {
                static let defaultValue = TestStringKeychainItem.defaultValue
                static let service = TestStringKeychainItem.service
            }

            try await withKeychain { keychain in
                try await confirmation { confirmation in
                    withObservationTracking({
                        #expect(throws: Never.self) {
                            try keychain.value(forItem: TestStringKeychainItem.self, account: Constants.testAccount)
                        }
                    }, onChange: {
                        confirmation()
                    })

                    try keychain.updateValue("Bar", forItem: TestAliasedStringKeychainItem.self, account: Constants.testAccount)
                }
            }
        }

        @Test(arguments: Constants.keychainItemValues)
        func testObservation_FailedUpdate_Observes(_ itemValue: any KeychainItemValueProtocol) async throws {
            func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
                try await withKeychain { keychain in
                    try await confirmation { confirmation in
                        withObservationTracking({
                            #expect(throws: Never.self) {
                                try keychain.value(forItem: Item.self, account: Constants.testAccount)
                            }
                        }, onChange: {
                            confirmation()
                        })

                        let thrownError = try #require(keychain.interface.performWithError(.interactionNotAllowed) {
                            #expect(throws: KeychainError.self) {
                                try keychain.updateValue(value, forItem: Item.self, account: Constants.testAccount)
                            }
                        })
                        #expect(thrownError ~= .interactionNotAllowed)
                    }
                }
            }

            func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
                try await projection(ItemValue.Item.self, value: itemValue.value)
            }

            try await unwrap(itemValue)
        }
    }
}

private func withKeychain<Output, Failure>(initialStorage storage: Dictionary<KeychainQuery, Data> = [:], perform body: (_ keychain: Keychain<MockKeychainInterface>) async throws(Failure) -> Output) async throws(Failure) -> Output {
    let interface = MockKeychainInterface(storage)

    let keychain = Keychain(interface: interface)

    return try await body(keychain)
}
