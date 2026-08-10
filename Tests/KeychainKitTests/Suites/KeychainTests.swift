
import Foundation
import Observation
import Testing

@testable import KeychainKit

@Suite
struct KeychainTests {

    @Test
    func testRead_Empty() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = keychain["Test"]
        #expect(initialValue == nil)
    }

    @Test
    func testReadDefaultValue_Empty() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = keychain["Test", default: "DefaultValue"]
        #expect(initialValue == "DefaultValue")

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == nil)
    }

    @Test
    func testReadUpdateDelete() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = keychain["Test"]
        #expect(initialValue == nil)

        let existingValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(existingValue == nil)

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Value")
    }

    @Test
    func testReadUpdateReadDefaultValueDelete() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = keychain["Test"]
        #expect(initialValue == nil)

        let existingValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(existingValue == nil)

        let existingValueWithDefault = keychain["Test", default: "DefaultValue"]
        #expect(existingValueWithDefault == "Value")

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Value")
    }

    @Test
    func testObservation_ReadSet() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        try await confirmation { confirmation in
            withObservationTracking({
                let value = keychain["Test"]
                #expect(value == nil)
            }, onChange: {
                confirmation()
            })

            let previousValue = try keychain.updateValue("Value", forKey: "Test")
            #expect(previousValue == nil)
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Value")
    }

    @Test
    func testObservation_SetReadSet() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(initialValue == nil)

        let value = keychain["Test"]
        #expect(value == "Value")

        try await confirmation { confirmation in
            withObservationTracking({
                let value = keychain["Test"]
                #expect(value == "Value")
            }, onChange: {
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == "Value")
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_Set_DoesNotObserve() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        try await confirmation(expectedCount: 0) { confirmation in
            withObservationTracking({
                let previousValue = try? keychain.updateValue("Value", forKey: "Test")
                #expect(previousValue == nil)
            }, onChange: {
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == "Value")
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_Delete_DoesNotObserve() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        try await confirmation(expectedCount: 0) { confirmation in
            withObservationTracking({
                let previousValue = try? keychain.removeValue(forKey: "Test")
                #expect(previousValue == nil)
            }, onChange: {
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == nil)
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_SetReadWithinChange() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(initialValue == nil)

        try await confirmation { confirmation in
            withObservationTracking({
                let value = keychain["Test"]
                #expect(value == "Value")
            }, onChange: {
                let value = keychain["Test"]
                #expect(value == "Value")
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == "Value")
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_SetSetWithinChange() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(initialValue == nil)

        try await confirmation { confirmation in
            withObservationTrackingOnce({
                let value = keychain["Test"]
                #expect(value == "Value")
            }, willSet: {
                let value = try? keychain.updateValue("Nested", forKey: "Test")
                #expect(value == "Value")
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == "Nested")
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_SetDeleteWithinChange() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(initialValue == nil)

        try await confirmation { confirmation in
            withObservationTrackingOnce({
                let value = keychain["Test"]
                #expect(value == "Value")
            }, willSet: {
                let value = try? keychain.removeValue(forKey: "Test")
                #expect(value == "Value")
                confirmation()
            })

            let previousValue = try keychain.updateValue("Updated", forKey: "Test")
            #expect(previousValue == nil)
        }

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Updated")
    }

    @Test
    func testObservation_UpdateEqualValue_DoesNotNotify() async throws {
        let keychain = Keychain(interface: MockKeychainInterface())

        let initialValue = try keychain.updateValue("Value", forKey: "Test")
        #expect(initialValue == nil)

        try await confirmation(expectedCount: 0) { confirmation in
            withObservationTracking({
                let value = keychain["Test"]
                #expect(value == "Value")
            }, onChange: {
                confirmation()
            })

            let previousValue = try keychain.updateValue("Value", forKey: "Test")
            #expect(previousValue == "Value")
        }
    }

    // MARK: - Cold Cache

    @Test
    func testRead_ColdCache_ReturnsExistingItem() async throws {
        let keychain = Keychain(interface: MockKeychainInterface(["Test": Data("Existing".utf8)]))

        let value = try keychain.value(forKey: "Test")
        #expect(value == "Existing")
    }

    @Test
    func testUpdate_ColdCache_ReturnsPreviousItem() async throws {
        let interface = MockKeychainInterface(["Test": Data("Existing".utf8)])
        let keychain = Keychain(interface: interface)

        let previousValue = try keychain.updateValue("Updated", forKey: "Test")
        #expect(previousValue == "Existing")
        #expect(try interface.value(forKey: "Test") == Data("Updated".utf8))
    }

    @Test
    func testRemove_ColdCache_ReturnsPreviousItem() async throws {
        let interface = MockKeychainInterface(["Test": Data("Existing".utf8)])
        let keychain = Keychain(interface: interface)

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == "Existing")
        #expect(try interface.value(forKey: "Test") == nil)
    }

    // MARK: - Stale Cache

    @Test
    func testRemove_StaleNegativeCache_StillRemovesItem() async throws {
        let interface = MockKeychainInterface()
        let keychain = Keychain(interface: interface)

        let initialValue = try keychain.value(forKey: "Test")
        #expect(initialValue == nil)

        // an external writer inserts an item behind the cache's back
        try interface.insertValue(Data("External".utf8), forKey: "Test")

        let deletedValue = try keychain.removeValue(forKey: "Test")
        #expect(deletedValue == nil)
        #expect(try interface.value(forKey: "Test") == nil)
    }

    @Test
    func testUpdate_StaleNegativeCache_RecoversFromDuplicate() async throws {
        let interface = MockKeychainInterface()
        let keychain = Keychain(interface: interface)

        let initialValue = try keychain.value(forKey: "Test")
        #expect(initialValue == nil)

        // an external writer inserts an item behind the cache's back
        try interface.insertValue(Data("External".utf8), forKey: "Test")

        let previousValue = try keychain.updateValue("Updated", forKey: "Test")
        #expect(previousValue == nil)
        #expect(try interface.value(forKey: "Test") == Data("Updated".utf8))
        #expect(try keychain.value(forKey: "Test") == "Updated")
    }

    // MARK: - Errors

    @Test
    func testRead_Error_PropagatesWithoutPoisoningCache() async throws {
        let interface = MockKeychainInterface(["Test": Data("Value".utf8)])
        let keychain = Keychain(interface: interface)

        #expect(throws: KeychainError.interactionNotAllowed) {
            try interface.performWithError(.interactionNotAllowed) { () throws(KeychainError) in
                try keychain.value(forKey: "Test")
            }
        }

        #expect(try keychain.value(forKey: "Test") == "Value")
    }

    @Test
    func testUpdate_Error_LeavesCacheAndStorageUnchanged() async throws {
        let interface = MockKeychainInterface(["Test": Data("Value".utf8)])
        let keychain = Keychain(interface: interface)

        let initialValue = try keychain.value(forKey: "Test")
        #expect(initialValue == "Value")

        #expect(throws: KeychainError.interactionNotAllowed) {
            try interface.performWithError(.interactionNotAllowed) { () throws(KeychainError) in
                try keychain.updateValue("Updated", forKey: "Test")
            }
        }

        #expect(try keychain.value(forKey: "Test") == "Value")
        #expect(try interface.value(forKey: "Test") == Data("Value".utf8))
    }

    // MARK: - Invalid Data

    @Test
    func testRead_InvalidUTF8_TreatedAsAbsent() async throws {
        let keychain = Keychain(interface: MockKeychainInterface(["Test": Data([0xFF, 0xFE, 0xFD])]))

        let value = try keychain.value(forKey: "Test")
        #expect(value == nil)
    }

    @Test
    func testUpdate_ColdCacheInvalidUTF8_OverwritesItem() async throws {
        let interface = MockKeychainInterface(["Test": Data([0xFF, 0xFE, 0xFD])])
        let keychain = Keychain(interface: interface)

        let previousValue = try keychain.updateValue("Updated", forKey: "Test")
        #expect(previousValue == nil)
        #expect(try keychain.value(forKey: "Test") == "Updated")
        #expect(try interface.value(forKey: "Test") == Data("Updated".utf8))
    }
}
