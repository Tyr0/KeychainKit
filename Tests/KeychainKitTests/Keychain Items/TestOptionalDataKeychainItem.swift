
import Foundation
import KeychainKit

enum TestOptionalDataKeychainItem: KeychainItemProtocol {

    static let defaultValue: Optional<Data> = nil

    static let service: String = "com.calderone.KeychainKit.TestOptionalData"
}
