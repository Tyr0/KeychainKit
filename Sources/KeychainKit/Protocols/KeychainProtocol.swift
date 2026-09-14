
import Observation

internal import os.log

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

    /// Returns the value for the given key, or `nil` when no item exists.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be queried.
    func value(forKey key: Key) throws(KeychainError) -> Value?

    /// Inserts or updates the value for the given key.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be updated.
    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError)

    /// Removes the value for the given key.
    ///
    /// Removing an absent item is not an error.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be modified.
    func removeValue(forKey key: Key) throws(KeychainError)
}

extension KeychainProtocol {

    /// Accesses the value for the given key, discarding any errors.
    ///
    /// Reading returns `nil` when the item is absent or the read fails; use
    /// ``value(forKey:)`` to distinguish the two. Writing a value inserts or updates the
    /// item; writing `nil` removes it. A failed write is logged and discarded — use
    /// ``updateValue(_:forKey:)`` or ``removeValue(forKey:)`` when failure must be
    /// observable.
    public subscript(key: Key) -> Value? {
        get {
            do {
                return try self.value(forKey: key)
            } catch {
                Logger.keychain.error("Attempted to read \(key) but received error instead: \(error)")
            }

            return nil
        }
        nonmutating set {
            if let newValue = newValue {
                do {
                    try self.updateValue(newValue, forKey: key)
                } catch {
                    Logger.keychain.error("Attempted to update \(key) but received error instead: \(error)")
                }
            } else {
                do {
                    try self.removeValue(forKey: key)
                } catch {
                    Logger.keychain.error("Attempted to update \(key) but received error instead: \(error)")
                }
            }
        }
    }

    /// Reads the value for the given key, returning a default when the item is absent or
    /// the read fails.
    ///
    /// The default is not written to the keychain; subsequent reads evaluate it again
    /// until a value is stored for the key.
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        do {
            if let value = try self.value(forKey: key) {
                return value
            } else {
                return defaultValue()
            }
        } catch {
            Logger.keychain.error("Attempted to read \(key) but received error instead: \(error)")
        }

        return defaultValue()
    }
}
