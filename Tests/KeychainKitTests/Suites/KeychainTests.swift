
import Foundation
import Observation
import os.lock
import Testing

import KeychainKit

@Suite
struct KeychainTests {

    @Test
    func testEmpty_Read_ReturnsNil() async throws {
        await withKeychain { keychain in
            let initialValue = keychain["Test"]
            #expect(initialValue == nil)
        }
    }

    @Test
    func testEmpty_ReadWithDefault_ReturnsDefaultValue() async throws {
        await withKeychain { keychain in
            let initialValue = keychain["Test", default: "DefaultValue"]
            #expect(initialValue == "DefaultValue")
        }
    }

    @Test
    func testEmpty_Read_Update_Read_Remove_ReturnsNil() async throws {
        try await withKeychain { keychain in
            let initialValue = keychain["Test"]
            #expect(initialValue == nil)

            try keychain.updateValue("Value", forKey: "Test")

            let updatedValue = keychain["Test"]
            #expect(updatedValue == "Value")

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testEmpty_Read_Update_ReadWithDefault_Remove_ReturnsNil() async throws {
        try await withKeychain { keychain in
            let initialValue = keychain["Test"]
            #expect(initialValue == nil)

            try keychain.updateValue("Value", forKey: "Test")

            let existingValueWithDefault = keychain["Test", default: "DefaultValue"]
            #expect(existingValueWithDefault == "Value")

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Empty_Read_Update_Observes() async throws {
        try await withKeychain { keychain in
            try await confirmation { confirmation in
                withObservationTracking({
                    let value = keychain["Test"]
                    #expect(value == nil)
                }, onChange: {
                    confirmation()
                })

                try keychain.updateValue("Value", forKey: "Test")
            }

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Update_Read_Update_Observes() async throws {
        try await withKeychain { keychain in
            try keychain.updateValue("Value", forKey: "Test")

            let value = keychain["Test"]
            #expect(value == "Value")

            try await confirmation { confirmation in
                withObservationTracking({
                    let value = keychain["Test"]
                    #expect(value == "Value")
                }, onChange: {
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Update_DoesNotObserve() async throws {
        try await withKeychain { keychain in
            try await confirmation(expectedCount: 0) { confirmation in
                withObservationTracking({
                    #expect(throws: Never.self) {
                        try keychain.updateValue("Value", forKey: "Test")
                    }
                }, onChange: {
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Remove_DoesNotObserve() async throws {
        try await withKeychain { keychain in
            try await confirmation(expectedCount: 0) { confirmation in
                withObservationTracking({
                    #expect(throws: Never.self) {
                        try keychain.removeValue(forKey: "Test")
                    }
                }, onChange: {
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Update_ReadWithinChange_ReturnsPreviousValue() async throws {
        try await withKeychain { keychain in
            try keychain.updateValue("Value", forKey: "Test")

            try await confirmation { confirmation in
                withObservationTracking({
                    let value = keychain["Test"]
                    #expect(value == "Value")
                }, onChange: {
                    let value = keychain["Test"]
                    #expect(value == "Value")
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Update_UpdateWithinChange_PreservesOuterValue() async throws {
        try await withKeychain { keychain in
            try keychain.updateValue("Value", forKey: "Test")

            try await confirmation { confirmation in
                withObservationTrackingOnce({
                    let value = keychain["Test"]
                    #expect(value == "Value")
                }, willSet: {
                    #expect(throws: Never.self) {
                        try keychain.updateValue("Nested", forKey: "Test")
                    }
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            #expect(try keychain.value(forKey: "Test") == "Updated")
            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    @Test
    func testObservation_Update_RemoveWithinChange_PreservesOuterValue() async throws {
        try await withKeychain { keychain in
            try keychain.updateValue("Value", forKey: "Test")

            try await confirmation { confirmation in
                withObservationTrackingOnce({
                    let value = keychain["Test"]
                    #expect(value == "Value")
                }, willSet: {
                    #expect(throws: Never.self) {
                        try keychain.removeValue(forKey: "Test")
                    }
                    confirmation()
                })

                try keychain.updateValue("Updated", forKey: "Test")
            }

            #expect(try keychain.value(forKey: "Test") == "Updated")
            try keychain.removeValue(forKey: "Test")
            #expect(try keychain.interface.value(forKey: "Test") == nil)
        }
    }

    // MARK: - External Changes

    @Test
    func testRead_ExternalChanges_ReturnsCurrentStorage() throws {
        let interface = MockKeychainInterface()
        let keychain = Keychain(interface: interface)

        #expect(try keychain.value(forKey: "Test") == nil)
        try interface.insertValue(Data("External".utf8), forKey: "Test")
        #expect(try keychain.value(forKey: "Test") == "External")
        try interface.updateValue(Data("Replaced".utf8), forKey: "Test")
        #expect(try keychain.value(forKey: "Test") == "Replaced")
        try interface.removeValue(forKey: "Test")
        #expect(try keychain.value(forKey: "Test") == nil)
    }

    @Test
    func testUpdate_PreviouslyReadValue_OverwritesExternalChange() throws {
        let interface = MockKeychainInterface(["Test": Data("Original".utf8)])
        let keychain = Keychain(interface: interface)

        #expect(try keychain.value(forKey: "Test") == "Original")
        try interface.updateValue(Data("External".utf8), forKey: "Test")
        try keychain.updateValue("Original", forKey: "Test")
        #expect(try interface.value(forKey: "Test") == Data("Original".utf8))

        try interface.removeValue(forKey: "Test")
        try keychain.updateValue("Original", forKey: "Test")
        #expect(try interface.value(forKey: "Test") == Data("Original".utf8))
    }

    @Test
    func testRemove_ExternalInsertion_RemovesItem() throws {
        let interface = MockKeychainInterface()
        let keychain = Keychain(interface: interface)

        #expect(try keychain.value(forKey: "Test") == nil)
        try interface.insertValue(Data("External".utf8), forKey: "Test")
        try keychain.removeValue(forKey: "Test")
        #expect(try interface.value(forKey: "Test") == nil)
    }

    @Test
    func testUpdate_ExternalInsertion_RetriesUpdate() throws {
        let interface = InsertionRaceKeychainInterface()
        let keychain = Keychain(interface: interface)

        try keychain.updateValue("Requested", forKey: "Test")

        #expect(interface.operations.withLock { $0 } == ["update", "insert", "update"])
        #expect(try interface.value(forKey: "Test") == Data("Requested".utf8))
    }

    // MARK: - Errors

    @Test
    func testRead_Error_PropagatesAndRecovers() throws {
        let interface = MockKeychainInterface(["Test": Data("Value".utf8)])
        let keychain = Keychain(interface: interface)

        #expect(try keychain.value(forKey: "Test") == "Value")
        #expect(throws: KeychainError.interactionNotAllowed) {
            try interface.performWithError(.interactionNotAllowed) { () throws(KeychainError) in
                _ = try keychain.value(forKey: "Test")
            }
        }
        #expect(try keychain.value(forKey: "Test") == "Value")
    }

    @Test(arguments: [false, true])
    func testMutation_Error_PreservesStorageAndRecovers(remove: Bool) throws {
        let interface = MockKeychainInterface(["Test": Data("Value".utf8)])
        let keychain = Keychain(interface: interface)

        #expect(throws: KeychainError.interactionNotAllowed) {
            try interface.performWithError(.interactionNotAllowed) { () throws(KeychainError) in
                if remove {
                    try keychain.removeValue(forKey: "Test")
                } else {
                    try keychain.updateValue("Updated", forKey: "Test")
                }
            }
        }
        #expect(try interface.value(forKey: "Test") == Data("Value".utf8))
        if remove {
            try keychain.removeValue(forKey: "Test")
            #expect(try interface.value(forKey: "Test") == nil)
        } else {
            try keychain.updateValue("Updated", forKey: "Test")
            #expect(try interface.value(forKey: "Test") == Data("Updated".utf8))
        }
    }

    @Test
    func testObservation_ExternalUpdate_DoesNotObserve() async throws {
        let interface = MockKeychainInterface()
        let keychain = Keychain(interface: interface)

        try await confirmation(expectedCount: 0) { confirmation in
            withObservationTracking({
                _ = keychain["Test"]
            }, onChange: {
                confirmation()
            })
            try interface.insertValue(Data("External".utf8), forKey: "Test")
            #expect(try keychain.value(forKey: "Test") == "External")
        }
    }

    @Test
    func testObservation_UpdateSameValue_Observes() async throws {
        let keychain = Keychain(interface: MockKeychainInterface(["Test": Data("Value".utf8)]))

        try await confirmation { confirmation in
            withObservationTracking({
                _ = keychain["Test"]
            }, onChange: {
                confirmation()
            })
            try keychain.updateValue("Value", forKey: "Test")
        }
        #expect(try keychain.value(forKey: "Test") == "Value")
    }

    // MARK: - Invalid Data

    @Test
    func testRead_InvalidUTF8_ReturnsNil() async throws {
        try await withKeychain(initialStorage: ["Test": Data([0xFF, 0xFE, 0xFD])]) { keychain in
            let value = try keychain.value(forKey: "Test")
            #expect(value == nil)
        }
    }

    @Test
    func testUpdate_InvalidUTF8_OverwritesItem() async throws {
        try await withKeychain(initialStorage: ["Test": Data([0xFF, 0xFE, 0xFD])]) { keychain in
            let existingValue = try keychain.value(forKey: "Test")
            #expect(existingValue == nil)

            try keychain.updateValue("Updated", forKey: "Test")

            let updatedValue = try keychain.value(forKey: "Test")
            #expect(updatedValue == "Updated")
        }
    }
}

private func withKeychain<Output, Failure>(initialStorage storage: Dictionary<KeychainAttributes, Data> = [:], perform body: (_ keychain: Keychain<MockKeychainInterface>) async throws(Failure) -> Output) async throws(Failure) -> Output {
    let interface = MockKeychainInterface(storage)
    let keychain = Keychain(interface: interface)

    return try await body(keychain)
}

private struct InsertionRaceKeychainInterface: KeychainInterfaceProtocol {

    let operations = OSAllocatedUnfairLock(initialState: Array<String>())

    private let storage = MockKeychainInterface()

    func value(forKey key: Key) throws(KeychainError) -> Value? {
        return try self.storage.value(forKey: key)
    }

    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        self.operations.withLock { $0.append("update") }
        try self.storage.updateValue(value, forKey: key)
    }

    func insertValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        self.operations.withLock { $0.append("insert") }
        // Another writer inserts after the initial update found no item.
        try self.storage.insertValue(Data("External".utf8), forKey: key)
        try self.storage.insertValue(value, forKey: key)
    }

    func removeValue(forKey key: Key) throws(KeychainError) {
        try self.storage.removeValue(forKey: key)
    }
}
