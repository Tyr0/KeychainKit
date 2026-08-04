
import Observation

/// An observable, dictionary-like store of string secrets.
///
/// `KeychainProtocol` is the client-facing surface of the package, implemented by
/// ``Keychain``. The named methods throw ``KeychainError``; the subscripts are
/// non-throwing conveniences that discard errors.
public protocol KeychainProtocol: Observable, Sendable {

    /// The attributes identifying a stored item.
    typealias Key = KeychainAttributes

    /// The stored value type.
    typealias Value = String

    /// Accesses the value for the given key, discarding any errors.
    ///
    /// Reading returns `nil` when the item is absent or the read fails. Writing `nil`
    /// removes the item; a failed write is silently dropped.
    subscript(key: Key) -> Value? { get nonmutating set }

    /// Reads the value for the given key, returning a default when the item is absent or
    /// the read fails.
    subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value { get }

    /// Returns the value for the given key, or `nil` when no item exists.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be queried.
    func value(forKey key: Key) throws(KeychainError) -> Value?

    /// Inserts or updates the value for the given key, returning the previous value.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be updated.
    @discardableResult
    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) -> Value?

    /// Removes the value for the given key, returning the removed value.
    ///
    /// Removing an absent item is not an error.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be modified.
    @discardableResult
    func removeValue(forKey key: Key) throws(KeychainError) -> Value?
}

public extension KeychainProtocol {

    /// Accesses the value for a raw-representable key, such as a case of an enum whose
    /// raw value is ``KeychainAttributes``.
    @inlinable
    subscript<K>(key: K) -> Value? where K: RawRepresentable, K.RawValue == Key {
        get { self[key.rawValue] }
        nonmutating set { self[key.rawValue] = newValue }
    }

    /// Returns the value for the given key, or `nil` when no item exists.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be queried.
    @inlinable
    func value<K>(forKey key: K) throws(KeychainError) -> Value? where K: RawRepresentable, K.RawValue == Key {
        return try self.value(forKey: key.rawValue)
    }

    /// Inserts or updates the value for a raw-representable key, returning the previous
    /// value.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be updated.
    @discardableResult @inlinable
    func updateValue<K>(_ value: Value, forKey key: K) throws(KeychainError) -> Value? where K: RawRepresentable, K.RawValue == Key {
        return try self.updateValue(value, forKey: key.rawValue)
    }

    /// Removes the value for a raw-representable key, returning the removed value.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be modified.
    @discardableResult @inlinable
    func removeValue<K>(forKey key: K) throws(KeychainError) -> Value? where K: RawRepresentable, K.RawValue == Key {
        return try self.removeValue(forKey: key.rawValue)
    }
}
