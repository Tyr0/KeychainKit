import KeychainKit

enum TestStringKeychainItem: KeychainItemProtocol {

    static let defaultValue: String = "DefaultValue"

    static let service: String = "com.calderone.KeychainKit.TestString"
}
