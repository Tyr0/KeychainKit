
import Foundation
import Testing

@testable import KeychainKit

@Suite(ConditionTrait.disabled("System Keybag requires entitlements unavailable in Swift Package Manager"), ParallelizationTrait.serialized)
struct SystemKeychainInterfaceTests {

    private enum Constants {

        static let testAccount: String = "SystemKeychainInterfaceTests.TestAccount"

        static let testService: String = "SystemKeychainInterfaceTests.TestService"

        static let testSynchronizable: Bool = false

        static let testQuery = KeychainQuery(
            accessGroup: nil,
            account: Constants.testAccount,
            service: Constants.testService,
            synchronizable: .explicit(Constants.testSynchronizable),
        )
    }

    @Test
    func testEmpty_Read_ThrowsItemNotFound() async throws {
        let keychainInterface = SystemKeychainInterface()

        #expect(throws: KeychainInterfaceError.itemNotFound) {
            try keychainInterface.value(forQuery: Constants.testQuery)
        }
    }

    @Test
    func testEmpty_Remove_ThrowsItemNotFound() async throws {
        let keychainInterface = SystemKeychainInterface()

        #expect(throws: KeychainInterfaceError.itemNotFound) {
            try keychainInterface.removeValue(forQuery: Constants.testQuery)
        }
    }

    @Test
    func testEmpty_Insert_Read_Remove() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, attributes: KeychainAttributes.Modifications(
            account: Constants.testAccount,
            service: Constants.testService,
            synchronizable: Constants.testSynchronizable,
        ))

        let value = try keychainInterface.value(forQuery: Constants.testQuery)
        #expect(value == data)

        try keychainInterface.removeValue(forQuery: Constants.testQuery)
    }

    @Test
    func testEmpty_Insert_Read_Update_Read_Remove() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, attributes: KeychainAttributes.Modifications(
            account: Constants.testAccount,
            service: Constants.testService,
            synchronizable: Constants.testSynchronizable,
        ))

        let value = try keychainInterface.value(forQuery: Constants.testQuery)
        #expect(value == data)

        let updatedData = Data("Updated".utf8)
        try keychainInterface.updateValue(updatedData, forQuery: Constants.testQuery)

        let updatedValue = try keychainInterface.value(forQuery: Constants.testQuery)
        #expect(updatedValue == updatedData)

        try keychainInterface.removeValue(forQuery: Constants.testQuery)
    }

    @Test
    func testEmpty_Update_ThrowsItemNotFound() async throws {
        let keychainInterface = SystemKeychainInterface()

        #expect(throws: KeychainInterfaceError.itemNotFound) {
            let data = Data("Value".utf8)
            try keychainInterface.updateValue(data, forQuery: Constants.testQuery)
        }
    }

    @Test
    func testInsert_Read_Insert_ThrowsDuplicateItem() async throws {
        let keychainInterface = SystemKeychainInterface()

        let data = Data("Value".utf8)
        try keychainInterface.insertValue(data, attributes: KeychainAttributes.Modifications(
            account: Constants.testAccount,
            service: Constants.testService,
            synchronizable: Constants.testSynchronizable,
        ))

        let value = try keychainInterface.value(forQuery: Constants.testQuery)
        #expect(value == data)

        #expect(throws: KeychainInterfaceError.duplicateItem) {
            let updatedData = Data("Updated".utf8)
            try keychainInterface.insertValue(updatedData, attributes: KeychainAttributes.Modifications(
                account: Constants.testAccount,
                service: Constants.testService,
                synchronizable: Constants.testSynchronizable,
            ))
        }

        try keychainInterface.removeValue(forQuery: Constants.testQuery)
    }
}
