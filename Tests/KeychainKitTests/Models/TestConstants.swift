import Foundation
import KeychainKit

enum TestConstants {

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
