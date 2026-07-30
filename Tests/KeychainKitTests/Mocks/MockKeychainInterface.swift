
import Foundation
import Synchronization

@testable import KeychainKit

final class MockKeychainInterface: KeychainInterfaceProtocol {

    private struct State {

        var injectedError: KeychainError?

        var storage: Dictionary<Key, Value>
    }

    // MARK: - Properties

    private let state: Mutex<State>

    // MARK: - Lifecycle Functions

    init(_ storage: Dictionary<Key, Value> = [:]) {
        self.state = Mutex(State(storage: storage))
    }

    // MARK: - Functions

    func injectError(_ error: KeychainError?) {
        self.state.withLock { state in
            state.injectedError = error
        }
    }

    // MARK: - KeychainInterfaceProtocol Conformance

    func value(forKey key: Key) throws(KeychainError) -> Value? {
        return try self.state.withLock { state throws(KeychainError) in
            if let injectedError = state.injectedError {
                throw injectedError
            }

            return state.storage[key]
        }
    }

    func insertValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        try self.state.withLock { state throws(KeychainError) in
            if let injectedError = state.injectedError {
                throw injectedError
            }

            guard state.storage[key] == nil else {
                throw KeychainError.duplicateItem
            }

            let existingValue = state.storage.updateValue(value, forKey: key)
            precondition(existingValue == nil)
        }
    }

    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        try self.state.withLock { state throws(KeychainError) in
            if let injectedError = state.injectedError {
                throw injectedError
            }

            guard state.storage[key] != nil else {
                throw KeychainError.itemNotFound
            }

            let existingValue = state.storage.updateValue(value, forKey: key)
            precondition(existingValue != nil)
        }
    }

    func removeValue(forKey key: Key) throws(KeychainError) {
        try self.state.withLock { state throws(KeychainError) in
            if let injectedError = state.injectedError {
                throw injectedError
            }

            _ = state.storage.removeValue(forKey: key)
        }
    }
}
