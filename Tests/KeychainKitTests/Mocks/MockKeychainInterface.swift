
import Foundation
import KeychainKit
import os.lock

final class MockKeychainInterface: KeychainInterfaceProtocol {

    private struct State {

        var errors: Array<KeychainError> = []

        var storage: Dictionary<Key, Value>
    }

    // MARK: - Properties

    private let state: OSAllocatedUnfairLock<State>

    // MARK: - Lifecycle Functions

    init(_ storage: Dictionary<Key, Value> = [:]) {
        self.state = OSAllocatedUnfairLock(initialState: State(storage: storage))
    }

    // MARK: - Functions

    func performWithError<Result>(_ error: KeychainError, _ body: () throws(KeychainError) -> Result) throws(KeychainError) -> Result {
        self.state.withLock { state in
            state.errors.append(error)
        }

        defer {
            self.state.withLock { state in
                let removedError = state.errors.removeLast()
                assert(removedError == error)
            }
        }

        return try body()
    }

    // MARK: - KeychainInterfaceProtocol Conformance

    func value(forKey key: Key) throws(KeychainError) -> Value? {
        return try self.state.withLock(throwing: KeychainError.self) { state throws(KeychainError) in
            if let error = state.errors.last {
                throw error
            } else {
                return state.storage[key]
            }
        }
    }

    func insertValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        try self.state.withLock(throwing: KeychainError.self) { state throws(KeychainError) in
            if let error = state.errors.last {
                throw error
            }

            guard state.storage[key] == nil else {
                throw KeychainError.duplicateItem
            }

            let existingValue = state.storage.updateValue(value, forKey: key)
            precondition(existingValue == nil)
        }
    }

    func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        try self.state.withLock(throwing: KeychainError.self) { state throws(KeychainError) in
            if let error = state.errors.last {
                throw error
            }

            guard state.storage[key] != nil else {
                throw KeychainError.itemNotFound
            }

            let existingValue = state.storage.updateValue(value, forKey: key)
            precondition(existingValue != nil)
        }
    }

    func removeValue(forKey key: Key) throws(KeychainError) {
        try self.state.withLock(throwing: KeychainError.self) { state throws(KeychainError) in
            if let error = state.errors.last {
                throw error
            }

            _ = state.storage.removeValue(forKey: key)
        }
    }
}
