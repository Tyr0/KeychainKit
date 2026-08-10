
import Foundation
import Observation

internal import Synchronization

/// An observable cache over the provided raw keychain interface.
///
/// `Keychain` reads and writes string values through a backing ``KeychainInterfaceProtocol``,
/// caching each value in memory after first access and participating in Swift `Observation`
/// with per-key granularity: observers are notified only for the keys they read, and only
/// when a stored value actually changes.
///
/// The cache assumes this instance is the only writer for its keys; writes made to the
/// underlying store by other components are not observed once a key is cached. Removals
/// are always issued to the underlying store, regardless of cache state.
///
/// - Note: Failed operations are never cached — after a thrown error, the next access
///   queries the underlying store again.
public final class Keychain<Interface>: KeychainProtocol, Sendable where Interface: KeychainInterfaceProtocol {

    public typealias Key = KeychainProtocol.Key

    public typealias Value = KeychainProtocol.Value

    private struct CachedValue {

        let value: Value?

        init(_ value: Value? = nil) {
            self.value = value
        }
    }

    private struct State {

        var keychainCache: Dictionary<Key, CachedValue> = [:]
    }

    // MARK: - Properties

    public let interface: Interface

    private let observationRegistrar: ObservationRegistrar = ObservationRegistrar()

    private let state: Mutex<State> = Mutex(State())

    // MARK: - Lifecycle Functions

    /// Creates a keychain backed by the given interface.
    ///
    /// - Parameters:
    ///   - interface: The underlying store performing keychain operations.
    public init(interface: Interface) {
        self.interface = interface
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

        return try self.state.withLock { state throws(KeychainError) in
            if let cachedValue = state.keychainCache[key] {
                return cachedValue.value
            } else if let data = try self.interface.value(forKey: key),
                      let existingValue = String(validating: data, as: UTF8.self) {
                state.keychainCache[key] = CachedValue(existingValue)
                return existingValue
            } else {
                state.keychainCache[key] = CachedValue(nil)
                return nil
            }
        }
    }

    /// Inserts or updates the value for the given key, returning the previous value.
    ///
    /// Writing a value equal to the cached value is elided: the underlying store is not
    /// touched and no observers are notified.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The attributes identifying the item.
    /// - Returns: The previous value, or `nil` when no readable item existed.
    /// - Throws: A ``KeychainError`` when the underlying store cannot be updated; the
    ///   cache and store are left unchanged.
    @discardableResult
    public func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) -> Value? {
        // cache hot-path; no need to notify observers when we know the requested
        // value matches our most recently written value.
        if let cachedValue = self.state.withLock({ state in
            state.keychainCache[key]
        }), cachedValue.value == value {
            return cachedValue.value
        }

        return try self.withMutation(keyPath: \.[key]) { () throws(KeychainError) in
            return try self.state.withLock { state throws(KeychainError) in
                if let cachedValue = state.keychainCache[key] {
                    let existingValue = cachedValue.value

                    if existingValue != value {
                        let data = Data(value.utf8)
                        do throws(KeychainError) {
                            if existingValue != nil {
                                // try an update first, as we have a cached value here
                                try self.interface.updateValue(data, forKey: key)
                            } else {
                                try self.interface.insertValue(data, forKey: key)
                            }
                        } catch KeychainError.duplicateItem {
                            try self.interface.updateValue(data, forKey: key)
                        } catch KeychainError.itemNotFound {
                            try self.interface.insertValue(data, forKey: key)
                        }

                        state.keychainCache[key] = CachedValue(value)
                    }

                    return existingValue
                } else if let existingData = try self.interface.value(forKey: key) {
                    let existingValue = String(validating: existingData, as: UTF8.self)

                    if existingValue != value {
                        let data = Data(value.utf8)
                        do throws(KeychainError) {
                            // try an update first, as we found an existing value in the keychain
                            try self.interface.updateValue(data, forKey: key)
                        } catch KeychainError.itemNotFound {
                            try self.interface.insertValue(data, forKey: key)
                        }

                        state.keychainCache[key] = CachedValue(value)
                    }

                    return existingValue
                } else {
                    let data = Data(value.utf8)
                    do throws(KeychainError) {
                        // try an add first, as we did not find any existing value in the keychain
                        try self.interface.insertValue(data, forKey: key)
                    } catch KeychainError.duplicateItem {
                        try self.interface.updateValue(data, forKey: key)
                    }

                    state.keychainCache[key] = CachedValue(value)

                    return nil
                }
            }
        }
    }

    /// Removes the value for the given key, returning the removed value.
    ///
    /// The removal is always issued to the underlying store, even when the cache reports
    /// the item as absent, so a stale cache can never shield a persisted item from
    /// deletion. Removing an absent item is not an error.
    ///
    /// - Parameters:
    ///   - key: The attributes identifying the item.
    /// - Returns: The removed value, or `nil` when no readable item existed.
    /// - Throws: A ``KeychainError`` when the underlying store cannot be modified.
    @discardableResult
    public func removeValue(forKey key: Key) throws(KeychainError) -> Value? {
        return try self.withMutation(keyPath: \.[key]) { () throws(KeychainError) in
            return try self.state.withLock { state throws(KeychainError) in
                let existingValue: Value?
                if let cachedValue = state.keychainCache[key] {
                    existingValue = cachedValue.value
                } else if let data = try self.interface.value(forKey: key) {
                    existingValue = String(validating: data, as: UTF8.self)
                } else {
                    existingValue = nil
                }

                // always force a removal; an invalid or stale cache should never prevent
                // a persisted item from removal
                try self.interface.removeValue(forKey: key)

                state.keychainCache[key] = CachedValue(nil)

                return existingValue
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
