
import Foundation

/// A low-level store of keychain item data, consumed by ``Keychain``.
///
/// ``SystemKeychainInterface`` implements this protocol over the Security framework;
/// tests can conform an in-memory mock and inject it via ``Keychain/init(interface:)``.
/// Conformances map their underlying failures to ``KeychainError`` — ``Keychain`` relies
/// on ``KeychainError/itemNotFound`` to insert an item when an update finds none.
public protocol KeychainInterfaceProtocol: Sendable {

    /// The attributes identifying a stored item.
    typealias Key = KeychainAttributes

    /// The stored data type.
    typealias Value = Data

    /// Returns the data for the given key, or `nil` when no item exists.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be queried.
    nonisolated func value(forKey key: Key) throws(KeychainError) -> Value?

    /// Adds a new item for the given key.
    ///
    /// - Throws: ``KeychainError/duplicateItem`` when an item already exists for the key.
    nonisolated func insertValue(_ value: Value, forKey key: Key) throws(KeychainError)

    /// Updates the data of an existing item for the given key.
    ///
    /// - Throws: ``KeychainError/itemNotFound`` when no item exists for the key.
    nonisolated func updateValue(_ value: Value, forKey key: Key) throws(KeychainError)

    /// Removes the item for the given key.
    ///
    /// Removing an absent item is not an error.
    ///
    /// - Throws: A ``KeychainError`` when the store cannot be modified.
    nonisolated func removeValue(forKey key: Key) throws(KeychainError)
}
