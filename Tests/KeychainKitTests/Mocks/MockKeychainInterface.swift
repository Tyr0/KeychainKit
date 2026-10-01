import Foundation
import Observation
import os.lock

@testable import KeychainKit

final class MockKeychainInterface: ObservableKeychainInterfaceProtocol {

    private struct ResolvedIdentifier: Equatable, Hashable, Sendable {

        // MARK: - Properties

        let accessGroup: String

        let account: String

        let service: String

        let synchronizable: Bool

        // MARK: - Lifecycle Functions

        init(accessGroup: String, account: String, service: String, synchronizable: Bool) {
            self.accessGroup = accessGroup
            self.account = account
            self.service = service
            self.synchronizable = synchronizable
        }

        init(attributes: KeychainAttributes) {
            self.accessGroup = attributes.accessGroup
            self.account = attributes.account
            self.service = attributes.service
            self.synchronizable = attributes.synchronizable
        }

        // MARK: - Functions

        consuming func applying(_ modifications: borrowing KeychainAttributes.Modifications) -> Self {
            return ResolvedIdentifier(
                accessGroup: modifications.accessGroup ?? self.accessGroup,
                account: modifications.account ?? self.account,
                service: modifications.service ?? self.service,
                synchronizable: modifications.synchronizable ?? self.synchronizable,
            )
        }

        func matches(query: borrowing KeychainQuery) -> Bool {
            if let accessGroup = query.accessGroup {
                guard accessGroup == self.accessGroup else {
                    return false
                }
            }

            if let account = query.account {
                guard account == self.account else {
                    return false
                }
            }

            if let service = query.service {
                guard service == self.service else {
                    return false
                }
            }

            if case .explicit(let synchronizable) = query.synchronizable {
                guard synchronizable == self.synchronizable else {
                    return false
                }
            }

            return true
        }
    }

    private struct State {

        var errors: Array<KeychainInterfaceError> = []

        var storage: Dictionary<ResolvedIdentifier, Value>
    }

    // MARK: - Properties

    let observationRegistrar: ObservationRegistrar = ObservationRegistrar()

    private let state: OSAllocatedUnfairLock<State>

    // MARK: - Lifecycle Functions

    init(_ storage: Dictionary<KeychainQuery, Value> = [:]) {
        let resolvedStorage = storage.mapKeys { query in
            let resolvedAttributes = KeychainAttributes.resolving(query: query)
            let resolvedIdentifier = ResolvedIdentifier(attributes: resolvedAttributes)
            return resolvedIdentifier
        }
        self.state = OSAllocatedUnfairLock(initialState: State(storage: resolvedStorage))
    }

    // MARK: - Functions

    func performWithError<Failure, Result>(_ error: KeychainInterfaceError, _ body: () throws(Failure) -> Result) throws(Failure) -> Result {
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

    nonisolated func value(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) -> Value {
        return try self.state.withLock { state throws(KeychainInterfaceError) in
            if let error = state.errors.last {
                throw error
            }

            for (key, value) in state.storage where key.matches(query: query) {
                return value
            }

            throw .itemNotFound
        }
    }

    nonisolated func insertValue(_ value: Value, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError) {
        try self.state.withLock { state throws(KeychainInterfaceError) in
            if let error = state.errors.last {
                throw error
            }

            let resolvedAttributes = KeychainAttributes.resolving(modifications: modifications)
            let resolvedIdentifier = ResolvedIdentifier(attributes: resolvedAttributes)
            guard state.storage[resolvedIdentifier] == nil else {
                throw .duplicateItem
            }

            let existingValue = state.storage.updateValue(value, forKey: resolvedIdentifier)
            assert(existingValue == nil)
        }
    }

    nonisolated func updateValue(_ value: Value, forQuery query: borrowing KeychainQuery, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError) {
        try self.state.withLock { state throws(KeychainInterfaceError) in
            if let error = state.errors.last {
                throw error
            }

            var itemFound: Bool = false
            var updatedStorage: Dictionary<ResolvedIdentifier, Value> = [:]

            for (identifier, existingValue) in state.storage {
                guard identifier.matches(query: query) else {
                    guard updatedStorage.updateValue(existingValue, forKey: identifier) == nil else {
                        throw .duplicateItem
                    }

                    continue
                }

                let updatedIdentifier = identifier.applying(modifications)
                guard updatedStorage.updateValue(value, forKey: updatedIdentifier) == nil else {
                    throw .duplicateItem
                }

                itemFound = true
            }

            guard itemFound else {
                throw .itemNotFound
            }

            state.storage = updatedStorage
        }
    }

    nonisolated func removeValue(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) {
        try self.state.withLock { state throws(KeychainInterfaceError) in
            if let error = state.errors.last {
                throw error
            }

            var itemFound: Bool = false

            state.storage = state.storage.filter { key, _ in
                guard key.matches(query: query) else {
                    return true
                }

                itemFound = true

                return false
            }

            guard itemFound else {
                throw .itemNotFound
            }
        }
    }
}
