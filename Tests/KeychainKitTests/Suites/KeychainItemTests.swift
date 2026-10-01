
import Testing

@testable import KeychainKit

@Suite
struct KeychainItemTests {

    @Test(arguments: TestConstants.keychainItems)
    func testEmpty_Read_ReturnsDefaultValue(_ item: any KeychainItemProtocol.Type) async throws {
        func projection<Item>(_ item: Item.Type) async throws where Item: KeychainItemProtocol {
            let keychain = Keychain(interface: MockKeychainInterface())

            let keychainItem = KeychainItem(Item.self, keychain: keychain, account: TestConstants.testAccount)

            let initialValue = keychainItem.wrappedValue
            #expect(initialValue == Item.defaultValue)
        }

        try await projection(item)
    }

    @Test(arguments: TestConstants.keychainItemValues)
    func testEmpty_Read_Update_Read_ReturnsUpdatedValue_Delete_ReturnsDefaultValue(_ itemValue: any KeychainItemValueProtocol) async throws {
        func projection<Item>(_ item: Item.Type, value: Item.Value) async throws where Item: KeychainItemProtocol {
            let keychain = Keychain(interface: MockKeychainInterface())

            let keychainItem = KeychainItem(Item.self, keychain: keychain, account: TestConstants.testAccount)

            let initialValue = keychainItem.wrappedValue
            #expect(initialValue == Item.defaultValue)

            keychainItem.wrappedValue = value

            let updatedValue = keychainItem.wrappedValue
            #expect(updatedValue == value)

            try keychain.removeValue(forItem: Item.self, account: TestConstants.testAccount)

            let removedValue = keychainItem.wrappedValue
            #expect(removedValue == Item.defaultValue)
        }

        func unwrap<ItemValue>(_ itemValue: ItemValue) async throws where ItemValue: KeychainItemValueProtocol {
            try await projection(ItemValue.Item.self, value: itemValue.value)
        }

        try await unwrap(itemValue)
    }
}
