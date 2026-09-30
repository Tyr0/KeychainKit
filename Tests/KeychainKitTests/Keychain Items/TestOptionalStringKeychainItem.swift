
import KeychainKit

enum TestOptionalStringKeychainItem: KeychainItemProtocol {

    static let defaultValue: Optional<String> = nil

    static let service: String = "com.calderone.KeychainKit.TestOptionalString"
}
