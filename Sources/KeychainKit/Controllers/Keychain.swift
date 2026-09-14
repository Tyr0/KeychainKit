
import Foundation
import Observation

internal import os.lock

/// A ``KeychainProtocol`` implementation backed by the provided ``KeychainInterfaceProtocol``.
///
/// Every read queries the backing ``KeychainInterfaceProtocol`` without caching values
/// or absence.
///
/// Mutation attempts notify observers for the affected key, including equal-value writes,
/// removal of absent items, and failed operations. Callbacks run before the storage mutation.
/// Reads, writes, and removals through this instance share a lock. External writers and
/// direct interface calls are not covered by that lock. Updating a missing item requires
/// a separate insertion; if another writer inserts first, the update is retried once.
/// These operations are not an atomic transaction across writers.
///
/// - Note: External modifications are visible on the next read, but do not trigger
/// this instance's observation callbacks.
public final class Keychain<Interface>: KeychainProtocol, Sendable where Interface: KeychainInterfaceProtocol {

    public typealias Key = KeychainProtocol.Key

    public typealias Value = KeychainProtocol.Value

    // MARK: - Properties

    public let interface: Interface

    private let observationRegistrar: ObservationRegistrar = ObservationRegistrar()

    private let state: OSAllocatedUnfairLock<Void>

    // MARK: - Lifecycle Functions

    /// Creates a keychain backed by the given interface.
    ///
    /// - Parameters:
    ///   - interface: The underlying store performing keychain operations.
    public init(interface: Interface) {
        self.interface = interface
        self.state = OSAllocatedUnfairLock()
    }

    // MARK: - Private Functions

    private func access<Value>(keyPath: KeyPath<Keychain, Value>) {
        self.observationRegistrar.access(self, keyPath: keyPath)
    }

    private func withMutation<Failure, Result, Property>(keyPath: KeyPath<Keychain, Property>, _ mutation: () throws(Failure) -> Result) throws(Failure) -> Result {
        self.observationRegistrar.willSet(self, keyPath: keyPath)

        defer { self.observationRegistrar.didSet(self, keyPath: keyPath) }

        return try mutation()
    }

    // MARK: - KeychainProtocol Conformance

    /// Returns the value for the given key, or `nil` when no item exists.
    ///
    /// An item whose stored data is not valid UTF-8 is treated as absent; the next write
    /// replaces it.
    ///
    /// - Parameters:
    ///   - key: The attributes identifying the item.
    /// - Returns: The stored value, or `nil` when absent.
    /// - Throws: A ``KeychainError`` when the underlying store cannot be queried.
    public func value(forKey key: Key) throws(KeychainError) -> Value? {
        self.access(keyPath: \.[key])

        return try self.state.withLock(throwing: KeychainError.self) { () throws(KeychainError) in
            if let data = try self.interface.value(forKey: key),
               let existingValue = String(validating: data, as: UTF8.self) {
                return existingValue
            } else {
                return nil
            }
        }
    }

    /// Inserts or updates the value for the given key.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The attributes identifying the item.
    /// - Throws: A ``KeychainError`` when the underlying store cannot be updated.
    public func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        let data = Data(value.utf8)

        try self.withMutation(keyPath: \.[key]) { () throws(KeychainError) in
            try self.state.withLock(throwing: KeychainError.self) { () throws(KeychainError) in
                do throws(KeychainError) {
                    try self.interface.updateValue(data, forKey: key)
                } catch KeychainError.itemNotFound {
                    do throws(KeychainError) {
                        try self.interface.insertValue(data, forKey: key)
                    } catch KeychainError.duplicateItem {
                        try self.interface.updateValue(data, forKey: key)
                    }
                }
            }
        }
    }

    /// Removes the value for the given key.
    ///
    /// - Parameters:
    ///   - key: The attributes identifying the item.
    /// - Throws: A ``KeychainError`` when the underlying store cannot be modified.
    public func removeValue(forKey key: Key) throws(KeychainError) {
        try self.withMutation(keyPath: \.[key]) { () throws(KeychainError) in
            try self.state.withLock(throwing: KeychainError.self) { () throws(KeychainError) in
                try self.interface.removeValue(forKey: key)
            }
        }
    }
}

extension Keychain where Interface == SystemKeychainInterface {

    // MARK: - Lifecycle Functions

    /// Creates a keychain backed by the system keychain.
    @inlinable
    public convenience init() {
        self.init(interface: Interface())
    }
}
