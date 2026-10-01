import KeychainKit

enum TestInvalidKeychainRepresentableKeychainItem: KeychainItemProtocol { // swiftlint:disable:this type_name

    static let defaultValue: TestInvalidKeychainRepresentable = TestInvalidKeychainRepresentable()

    static let service: String = "com.calderone.KeychainKit.TestInvalidKeychainRepresentable"
}
