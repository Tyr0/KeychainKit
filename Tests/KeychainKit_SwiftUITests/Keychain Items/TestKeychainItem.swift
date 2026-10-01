import KeychainKit

enum TestKeychainItem: KeychainItemProtocol {

    static let defaultValue: Optional<String> = nil

    static let service: String = "com.calderone.KeychainKit.TestKeychainItem"
}
