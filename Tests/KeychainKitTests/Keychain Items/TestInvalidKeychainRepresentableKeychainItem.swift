
import KeychainKit

enum TestInvalidKeychainRepresentableKeychainItem: KeychainItemProtocol {

    static let defaultValue: TestInvalidKeychainRepresentable = TestInvalidKeychainRepresentable()

    static let service: String = "com.calderone.KeychainKit.TestInvalidKeychainRepresentable"
}
