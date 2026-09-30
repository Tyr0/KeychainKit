
import Foundation
import KeychainKit

enum TestDataKeychainItem: KeychainItemProtocol {

    static let defaultValue: Data = Data("DefaultValue".utf8)

    static let service: String = "com.calderone.KeychainKit.TestData"
}
