
import Foundation
import Observation

internal import os.lock

/// A ``KeychainProtocol`` implementation backed by the provided ``KeychainInterfaceProtocol``.
///
/// Use ``default``, `Keychain()`, or `Keychain(accessGroup:)` for the system keychain, or
/// inject another interface, such as an in-memory mock, with
/// `Keychain(accessGroup:interface:)`.
///
/// ## Storage
///
/// Each item is a generic password identified by the item type's
/// ``KeychainItemProtocol/service``, the account, this instance's ``accessGroup``, and
/// whether the item's policy is synchronizable. Item types that share a service share
/// stored items.
///
/// Every read queries the backing interface; neither values nor their absence are cached,
/// so changes made by other writers are visible on the next read.
///
/// ## Observation
///
/// Reads register observation for their service and account. Updates and removals
/// through this instance notify those observers, including equal-value writes, removals
/// of absent items, and failed operations, so a notification does not prove storage
/// changed. `willSet` is delivered before the lock is taken and `didSet` after it is
/// released, so observers may read from this instance.
///
/// Every `Keychain<SystemKeychainInterface>` created through `Keychain()`,
/// `Keychain(accessGroup:)`, or `Keychain(accessGroup:interface:)` with a concrete
/// ``SystemKeychainInterface`` shares observation, so updates and removals through any of
/// them notify readers of the same service and account on all of them, regardless of
/// access group. Generic code that creates a `Keychain<Interface>` resolves to the
/// unconstrained initializer and does not share observation, even when `Interface` is
/// ``SystemKeychainInterface``. Keychains backed by any other interface notify only
/// their own observers.
///
/// Changes made by other writers, such as other processes or direct interface calls, do
/// not notify observers.
///
/// ## Concurrency
///
/// Reads, updates, and removals through this instance are serialized by a lock that is
/// held for the duration of the interface calls. The lock is not reentrant: an interface
/// must not call back into the same `Keychain`. Other writers are not covered by the lock.
///
/// Updating an absent item issues an update, then an insertion; if another writer inserts
/// first, the update is retried once. These steps are not an atomic transaction across
/// writers.
public final class Keychain<Interface>: KeychainProtocol, Sendable where Interface: KeychainInterfaceProtocol {

    // MARK: - Properties

    /// The access group items are scoped to.
    ///
    /// When `nil`, new items are inserted into the app's first access group, while reads,
    /// updates, and removals match items in every access group the app belongs to.
    public let accessGroup: String?

    /// The store performing keychain operations.
    public let interface: Interface

    /// The observation store which should be notified of queries and modifications.
    private let observationRegistrar: ObservationRegistrar

    private let state: OSAllocatedUnfairLock<Void>

    // MARK: - Lifecycle Functions

    /// Creates a keychain backed by the given interface.
    ///
    /// - Parameters:
    ///   - accessGroup: The access group to scope items to, or `nil` for the app's
    ///     default group on insertion and every group on reads, updates, and removals.
    ///   - interface: The store performing keychain operations.
    ///   - observationRegistrar: The observation store which should be notified of queries and modifications.
    private init(accessGroup: String? = nil, interface: Interface, observationRegistrar: ObservationRegistrar) {
        self.accessGroup = accessGroup
        self.interface = interface
        self.observationRegistrar = observationRegistrar
        self.state = OSAllocatedUnfairLock()
    }

    /// Creates a keychain backed by the given interface.
    ///
    /// - Parameters:
    ///   - accessGroup: The access group to scope items to, or `nil` for the app's
    ///     default group on insertion and every group on reads, updates, and removals.
    ///   - interface: The store performing keychain operations.
    public convenience init(accessGroup: String? = nil, interface: Interface) {
        self.init(accessGroup: accessGroup, interface: interface, observationRegistrar: ObservationRegistrar())
    }

    // MARK: - Private Functions

    private subscript(observationKeyPathForAccount account: String, service service: String) -> Void {
        fatalError()
    }

    private func observationKeyPath<Item>(forItem item: Item.Type = Item.self, account: String) -> KeyPath<Keychain, Void> where Item: KeychainItemProtocol {
        // Keyed by the stored item's service and account rather than the item type, so item
        // types that share a service also share notifications.
        return \.[observationKeyPathForAccount: account, service: Item.service]
    }

    private func access<Value>(keyPath: KeyPath<Keychain, Value>) {
        self.observationRegistrar.access(self, keyPath: keyPath)
    }

    private func withMutation<Failure, Result, Property>(keyPath: KeyPath<Keychain, Property>, _ mutation: () throws(Failure) -> Result) throws(Failure) -> Result {
        self.observationRegistrar.willSet(self, keyPath: keyPath)

        defer { self.observationRegistrar.didSet(self, keyPath: keyPath) }

        return try mutation()
    }

    private func makeKeychainQuery<Item>(_ item: Item.Type = Item.self, account: String) -> KeychainQuery where Item: KeychainItemProtocol {
        return KeychainQuery(
            accessGroup: self.accessGroup,
            account: account,
            service: Item.service,
            synchronizable: .explicit(Item.policy.synchronizable),
        )
    }

    private func makeInsertAttributes<Item>(_ item: Item.Type = Item.self, account: String) -> KeychainAttributes.Modifications where Item: KeychainItemProtocol {
        return KeychainAttributes.Modifications(
            accessibility: Item.policy.accessibility,
            accessGroup: self.accessGroup,
            account: account,
            service: Item.service,
            synchronizable: Item.policy.synchronizable,
        )
    }

    private func makeUpdateAttributes<Item>(_ item: Item.Type = Item.self) -> KeychainAttributes.Modifications where Item: KeychainItemProtocol  {
        return KeychainAttributes.Modifications()
    }

    // MARK: - KeychainProtocol Conformance

    /// Returns the item's value for the given account, or its default value when no item exists.
    ///
    /// Registers observation for the item's service and account, even when the read fails.
    /// An item whose stored data cannot be decoded is left unchanged; the next write
    /// replaces it.
    ///
    /// - Parameters:
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Returns: The stored value, or ``KeychainItemProtocol/defaultValue`` when no item exists.
    /// - Throws: ``KeychainError/decodingError(_:)`` when the stored data cannot be decoded,
    ///   or ``KeychainError/securityError(_:)`` when the store cannot be queried.
    public func value<Item>(forItem item: Item.Type, account: String) throws(KeychainError) -> Item.Value where Item: KeychainItemProtocol {
        self.access(keyPath: self.observationKeyPath(forItem: Item.self, account: account))

        let keychainRepresentation: KeychainRepresentable.KeychainRepresentation
        do throws(KeychainInterfaceError) {
            let query = self.makeKeychainQuery(Item.self, account: account)
            keychainRepresentation = try self.state.withLock { () throws(KeychainInterfaceError) in
                return try self.interface.value(forQuery: query)
            }
        } catch .itemNotFound {
            return Item.defaultValue
        } catch {
            throw .securityError(error)
        }

        do throws(DecodingError) {
            return try Item.Value(keychainRepresentation: keychainRepresentation)
        } catch {
            throw .decodingError(error)
        }
   }

    /// Inserts or updates the item's value for the given account.
    ///
    /// The value is encoded before observers are notified, so an encoding failure does not
    /// notify. A value whose ``KeychainRepresentable/keychainRepresentation`` is `nil`
    /// removes the item, as ``removeValue(forItem:account:)`` does.
    ///
    /// An existing item's data is replaced and its protection is unchanged. An absent item
    /// is inserted with the item type's ``KeychainItemProtocol/policy``.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Throws: ``KeychainError/encodingError(_:)`` when the value cannot be encoded,
    ///   or ``KeychainError/securityError(_:)`` when the store cannot be updated.
    public func updateValue<Item>(_ value: Item.Value, forItem item: Item.Type, account: String) throws(KeychainError) where Item: KeychainItemProtocol {
        let keychainRepresentation: KeychainRepresentable.KeychainRepresentation?
        do throws(EncodingError) {
            keychainRepresentation = try value.keychainRepresentation
        } catch {
            throw .encodingError(error)
        }

        guard let keychainRepresentation = keychainRepresentation else {
            return try self.removeValue(forItem: Item.self, account: account)
        }

        try self.withMutation(keyPath: self.observationKeyPath(forItem: Item.self, account: account)) { () throws(KeychainError) in
            try self.state.withLock { () throws(KeychainError) in
                let query = self.makeKeychainQuery(Item.self, account: account)
                let updateAttributes = self.makeUpdateAttributes(Item.self)

                do throws(KeychainInterfaceError) {
                    try self.interface.updateValue(keychainRepresentation, forQuery: query, attributes: updateAttributes)
                } catch .itemNotFound {
                    let insertAttributes = self.makeInsertAttributes(Item.self, account: account)
                    do throws(KeychainInterfaceError) {
                        try self.interface.insertValue(keychainRepresentation, attributes: insertAttributes)
                    } catch .duplicateItem {
                        do throws(KeychainInterfaceError) {
                            try self.interface.updateValue(keychainRepresentation, forQuery: query, attributes: updateAttributes)
                        } catch {
                            throw .securityError(error)
                        }
                    } catch {
                        throw .securityError(error)
                    }
                } catch {
                    throw .securityError(error)
                }
            }
        }
    }

    /// Removes the item's value for the given account.
    ///
    /// Removing an absent item is not an error, and still notifies observers.
    ///
    /// - Parameters:
    ///   - item: The item definition.
    ///   - account: The account the item is stored under.
    /// - Throws: ``KeychainError/securityError(_:)`` when the store cannot be modified.
    public func removeValue<Item>(forItem item: Item.Type, account: String) throws(KeychainError) where Item: KeychainItemProtocol {
        try self.withMutation(keyPath: self.observationKeyPath(forItem: Item.self, account: account)) { () throws(KeychainError) in
            try self.state.withLock { () throws(KeychainError) in
                let query = self.makeKeychainQuery(Item.self, account: account)

                do throws(KeychainInterfaceError) {
                    try self.interface.removeValue(forQuery: query)
                } catch .itemNotFound {
                    return
                } catch {
                    throw .securityError(error)
                }
            }
        }
    }
}

extension Keychain where Interface == SystemKeychainInterface {

    /// The shared keychain backed by `SystemKeychainInterface.default`.
    public static let `default`: Keychain<SystemKeychainInterface> = Keychain<SystemKeychainInterface>(accessGroup: nil, interface: .default)

    // MARK: - Lifecycle Functions

    /// Creates a keychain backed by the system keychain.
    ///
    /// - Parameters:
    ///   - accessGroup: The access group to scope items to, or `nil` for the app's
    ///     default group on insertion and every group on reads, updates, and removals.
    ///   - interface: The system keychain interface.
    public convenience init(accessGroup: String? = nil, interface: Interface = .default) {
        self.init(accessGroup: accessGroup, interface: interface, observationRegistrar: interface.observationRegistrar)
    }
}

extension Keychain where Interface: ObservableKeychainInterfaceProtocol {

    // MARK: - Lifecycle Functions

    /// Creates a keychain that shares observation with every keychain backed by the same storage.
    ///
    /// - Parameters:
    ///   - accessGroup: The access group to scope items to, or `nil` for the app's
    ///     default group on insertion and every group on reads, updates, and removals.
    ///   - interface: The store performing keychain operations.
    internal convenience init(accessGroup: String? = nil, interface: Interface) {
        self.init(accessGroup: accessGroup, interface: interface, observationRegistrar: interface.observationRegistrar)
    }
}
