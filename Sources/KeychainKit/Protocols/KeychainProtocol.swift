import Observation

internal import os.log

/// An observable store of typed keychain items.
///
/// `KeychainProtocol` is the client-facing surface of the package, implemented by
/// ``Keychain``. Each item is described by a type conforming to ``KeychainItemProtocol``
/// and addressed by that type together with an account name.
///
/// The named methods throw ``KeychainError``. The subscript is a non-throwing
/// convenience that logs and discards errors.
///
/// Depend on `KeychainProtocol` rather than a concrete ``Keychain`` so an in-memory
/// implementation can be injected in tests.
public protocol KeychainProtocol: Observable, Sendable {

    /// Returns the item's value for the given account, or its default value when no item exists.
    ///
    /// - Parameters:
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Returns: The stored value, or ``KeychainItemProtocol/defaultValue`` when no item exists.
    /// - Throws: ``KeychainError/decodingError(_:)`` when the stored data cannot be decoded,
    ///   or ``KeychainError/securityError(_:)`` when the store cannot be queried.
    func value<Item>(forItem item: Item.Type, account: String) throws(KeychainError) -> Item.Value where Item: KeychainItemProtocol

    /// Inserts or updates the item's value for the given account.
    ///
    /// A value whose ``KeychainRepresentable/keychainRepresentation`` is `nil`, such as
    /// `Optional.none`, removes the item instead. Subsequent reads then return
    /// ``KeychainItemProtocol/defaultValue``, which is not necessarily `nil`.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Throws: ``KeychainError/encodingError(_:)`` when the value cannot be encoded,
    ///   or ``KeychainError/securityError(_:)`` when the store cannot be updated.
    func updateValue<Item>(_ value: Item.Value, forItem item: Item.Type, account: String) throws(KeychainError) where Item: KeychainItemProtocol

    /// Removes the item's value for the given account.
    ///
    /// Removing an absent item is not an error.
    ///
    /// - Parameters:
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Throws: ``KeychainError/securityError(_:)`` when the store cannot be modified.
    func removeValue<Item>(forItem item: Item.Type, account: String) throws(KeychainError) where Item: KeychainItemProtocol
}

extension KeychainProtocol {

    /// Accesses the item's value for the given account, logging and discarding any errors.
    ///
    /// Reading returns ``KeychainItemProtocol/defaultValue`` both when no item exists and
    /// when the read fails; use ``value(forItem:account:)`` to distinguish the two, for
    /// example to tell an absent item from a locked device. Writing behaves like
    /// ``updateValue(_:forItem:account:)``, including removal when the value is `nil`.
    ///
    /// ```swift
    /// keychain[AuthTokenItem.self, account: userID] = "abc123"
    /// let token = keychain[AuthTokenItem.self, account: userID]
    /// ```
    ///
    /// - Parameters:
    ///   - item: The item definition. May be inferred from the context.
    ///   - account: The account the item is stored under.
    public subscript<Item>(item: Item.Type = Item.self, account account: String) -> Item.Value where Item: KeychainItemProtocol {
        get {
            do {
                return try self.value(forItem: Item.self, account: account)
            } catch {
                Logger.keychain.error("Attempted to read \(_typeName(Item.self)) but received error instead: \(error)")
            }

            return Item.defaultValue
        }
        nonmutating set {
            do {
                try self.updateValue(newValue, forItem: Item.self, account: account)
            } catch {
                Logger.keychain.error("Attempted to update \(_typeName(Item.self)) but received error instead: \(error)")
            }
        }
    }
}
