
import Foundation
import Testing

@testable import KeychainKit

@Suite(ConditionTrait.disabled("System Keybag requires entitlements unavailable in Swift Package Manager"), ParallelizationTrait.serialized)
struct SystemKeychainInterfaceTests {

    @Test
    func testReadEmpty() async throws {
        let keychainInterface = SystemKeychainInterface()

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == nil)
    }

    @Test
    func testDeleteEmpty() async throws {
        let keychainInterface = SystemKeychainInterface()

        try keychainInterface.removeValue(forKey: "Test")
    }

    @Test
    func testInsertReadDelete() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, forKey: "Test")

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == data)

        try keychainInterface.removeValue(forKey: "Test")
    }

    @Test
    func testInsertReadUpdateReadDelete() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, forKey: "Test")

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == data)

        let updatedData = Data("Updated".utf8)
        try keychainInterface.updateValue(updatedData, forKey: "Test")

        let updatedValue = try keychainInterface.value(forKey: "Test")
        #expect(updatedValue == updatedData)

        try keychainInterface.removeValue(forKey: "Test")
    }

    @Test
    func testUpdate_ThrowsNotFound() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        #expect(throws: KeychainError.itemNotFound) {
            try keychainInterface.updateValue(data, forKey: "Test")
        }
    }

    @Test
    func testInsertReadInsertDelete_ThrowsDuplicate() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, forKey: "Test")

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == data)

        let updatedData = Data("Updated".utf8)
        #expect(throws: KeychainError.duplicateItem) {
            try keychainInterface.insertValue(updatedData, forKey: "Test")
        }

        try keychainInterface.removeValue(forKey: "Test")
    }
}
