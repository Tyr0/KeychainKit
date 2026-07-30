
import Observation

public protocol KeychainProtocol: Observable, Sendable {

    typealias Key = KeychainAttributes

    typealias Value = String

    subscript(key: Key) -> Value? { get nonmutating set }

    subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value { get }

    func value(forKey key: Key) throws(KeychainError) -> Value?

    @discardableResult
    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) -> Value?

    @discardableResult
    func removeValue(forKey key: Key) throws(KeychainError) -> Value?
}

public extension KeychainProtocol {

    @inlinable
    subscript<K>(key: K) -> Value? where K: RawRepresentable, K.RawValue == Key {
        get { self[key.rawValue] }
        set { self[key.rawValue] = newValue }
    }

    @discardableResult @inlinable
    func updateValue<K>(_ value: Value, forKey key: K) throws(KeychainError) -> Value? where K: RawRepresentable, K.RawValue == Key {
        return try self.updateValue(value, forKey: key.rawValue)
    }

    @discardableResult @inlinable
    func removeValue<K>(forKey key: K) throws(KeychainError) -> Value? where K: RawRepresentable, K.RawValue == Key {
        return try self.removeValue(forKey: key.rawValue)
    }
}
