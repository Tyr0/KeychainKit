
import Foundation
import Observation

internal import Synchronization

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

    let interface: Interface

    private let observationRegistrar: ObservationRegistrar = ObservationRegistrar()

    private let state: Mutex<State> = Mutex(State())

    // MARK: - Lifecycle Functions

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

    public subscript(key: Key) -> Value? {
        get {
            return try? self.value(forKey: key)
        }
        set {
            if let newValue = newValue {
                _ = try? self.updateValue(newValue, forKey: key)
            } else {
                _ = try? self.removeValue(forKey: key)
            }
        }
    }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        do {
            if let value = try self.value(forKey: key) {
                return value
            } else {
                return defaultValue()
            }
        } catch {
            return defaultValue()
        }
    }

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

    @discardableResult
    public func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) -> Value? {
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

    public convenience init() {
        self.init(interface: Interface())
    }
}
