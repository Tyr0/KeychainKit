
import Foundation

public protocol KeychainInterfaceProtocol: Sendable {

    typealias Key = KeychainAttributes

    typealias Value = Data

    nonisolated func value(forKey key: Key) throws(KeychainError) -> Value?

    nonisolated func insertValue(_ value: Value, forKey key: Key) throws(KeychainError)

    nonisolated func updateValue(_ value: Value, forKey key: Key) throws(KeychainError)

    nonisolated func removeValue(forKey key: Key) throws(KeychainError)
}
