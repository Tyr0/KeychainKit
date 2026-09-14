
import Foundation
import Testing

@testable import KeychainKit

@Suite(ConditionTrait.disabled("System Keybag requires entitlements unavailable in Swift Package Manager"), ParallelizationTrait.serialized)
struct SystemKeychainInterfaceTests {

    @Test
    func testEmpty_Read_ReturnsNil() async throws {
        let keychainInterface = SystemKeychainInterface()

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == nil)
    }

    @Test
    func testEmpty_Remove_DoesNotThrow() async throws {
        let keychainInterface = SystemKeychainInterface()

        try keychainInterface.removeValue(forKey: "Test")
    }

    @Test
    func testEmpty_Insert_Read_Remove() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, forKey: "Test")

        let value = try keychainInterface.value(forKey: "Test")
        #expect(value == data)

        try keychainInterface.removeValue(forKey: "Test")
    }

    @Test
    func testEmpty_Insert_Read_Update_Read_Remove() async throws {
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
    func testEmpty_Update_ThrowsItemNotFound() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        #expect(throws: KeychainError.itemNotFound) {
            try keychainInterface.updateValue(data, forKey: "Test")
        }
    }

    @Test
    func testInsert_Read_Insert_ThrowsDuplicateItem() async throws {
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
