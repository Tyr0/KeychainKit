import Foundation

/// A low-level store of generic password items, consumed by ``Keychain``.
///
/// ``SystemKeychainInterface`` implements this protocol over the Security framework.
/// Tests can conform an in-memory implementation and inject it with
/// ``Keychain/init(accessGroup:interface:)``.
///
/// Conformances mirror the semantics of the Security framework's `SecItem` functions,
/// and report failures as ``KeychainInterfaceError`` status codes. ``Keychain`` relies on
/// ``KeychainInterfaceError/itemNotFound`` and ``KeychainInterfaceError/duplicateItem``
/// to choose between updating and inserting an item.
public protocol KeychainInterfaceProtocol: Sendable {

    /// The stored data type.
    typealias Value = Data

    /// Returns the data of the first item matching the query.
    ///
    /// - Parameters:
    ///   - query: The criteria selecting the item.
    /// - Returns: The item's data.
    /// - Throws: ``KeychainInterfaceError/itemNotFound`` when no item matches, or another
    ///   ``KeychainInterfaceError`` when the store cannot be queried.
    nonisolated func value(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) -> Value

    /// Adds a new item with the given data and attributes.
    ///
    /// Attributes left `nil` take the store's defaults: an empty account and service,
    /// the app's first access group, and not synchronizable.
    ///
    /// - Parameters:
    ///   - value: The item's data.
    ///   - modifications: The attributes of the new item.
    /// - Throws: ``KeychainInterfaceError/duplicateItem`` when an item with the same access
    ///   group, account, service, and synchronizable flag exists, or another
    ///   ``KeychainInterfaceError`` when the store cannot be modified.
    nonisolated func insertValue(_ value: Value, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError)

    /// Replaces the data of every item matching the query, and applies the given attributes.
    ///
    /// Attributes left `nil` are unchanged.
    ///
    /// - Parameters:
    ///   - value: The new data.
    ///   - query: The criteria selecting the items.
    ///   - modifications: The attributes to change.
    /// - Throws: ``KeychainInterfaceError/itemNotFound`` when no item matches,
    ///   ``KeychainInterfaceError/duplicateItem`` when the change would collide with
    ///   another item, or another ``KeychainInterfaceError`` when the store cannot be modified.
    nonisolated func updateValue(_ value: Value, forQuery query: borrowing KeychainQuery, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError)

    /// Removes every item matching the query.
    ///
    /// - Parameters:
    ///   - query: The criteria selecting the items.
    /// - Throws: ``KeychainInterfaceError/itemNotFound`` when no item matches, or another
    ///   ``KeychainInterfaceError`` when the store cannot be modified.
    nonisolated func removeValue(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError)
}

extension KeychainInterfaceProtocol {

    /// Replaces the data of every item matching the query, leaving its attributes unchanged.
    @inlinable
    nonisolated func updateValue(_ value: Value, forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) {
        return try self.updateValue(value, forQuery: query, attributes: KeychainAttributes.Modifications())
    }
}
