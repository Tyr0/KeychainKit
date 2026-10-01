import Foundation
import Observation

internal import os.log
internal import Security

/// A ``KeychainInterfaceProtocol`` conformance backed by the Security framework.
///
/// Stores generic password items (`kSecClassGenericPassword`) in the data-protection
/// keychain (`kSecUseDataProtectionKeychain`) on every platform. Each call builds a new
/// query and passes Security's status code through unchanged as a ``KeychainInterfaceError``.
///
/// Updates and removals affect every item matching the query, matching the behavior of
/// `SecItemUpdate` and `SecItemDelete`.
///
/// - Note: On macOS the data-protection keychain requires a signed app with an
///   application identifier; unsigned processes, including Swift package test runners,
///   fail with ``KeychainInterfaceError/missingEntitlement``.
public struct SystemKeychainInterface: KeychainInterfaceProtocol {

    // MARK: - Static Properties

    /// The shared system keychain interface.
    public static let `default` = SystemKeychainInterface()

    // Every value addresses the same system keychain, so all values share one registrar.
    private static let sharedObservationRegistrar: ObservationRegistrar = ObservationRegistrar()

    // MARK: - Lifecycle Functions

    /// Creates a system keychain interface.
    public init() {
    }

    // MARK: - Private Functions

    private static func withSecurityInvocation(perform body: () -> OSStatus) throws(KeychainInterfaceError) {
        let status = body()
        if status != errSecSuccess {
            throw KeychainInterfaceError(rawValue: status)
        }
    }

    private static func apply(_ modifications: KeychainAttributes.Modifications, to attributes: inout Dictionary<CFString, CFTypeRef>) {
        if let accessibility = modifications.accessibility {
            attributes[kSecAttrAccessible] = accessibility.securityValue
        }

        if let accessGroup = modifications.accessGroup {
            attributes[kSecAttrAccessGroup] = accessGroup.securityValue
        }

        if let account = modifications.account {
            attributes[kSecAttrAccount] = account.securityValue
        }

        if let service = modifications.service {
            attributes[kSecAttrService] = service.securityValue
        }

        if let synchronizable = modifications.synchronizable {
            attributes[kSecAttrSynchronizable] = synchronizable.securityValue
        }
    }

    // MARK: - KeychainInterfaceProtocol Conformance

    public nonisolated func value(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) -> Value {
        var matching: Dictionary<CFString, CFTypeRef> = [
            kSecAttrSynchronizable: query.synchronizable.securityValue,
            kSecClass: kSecClassGenericPassword,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: kCFBooleanTrue,
            kSecUseDataProtectionKeychain: kCFBooleanTrue,
        ]

        if let accessGroup = query.accessGroup {
            matching[kSecAttrAccessGroup] = accessGroup.securityValue
        }

        if let account = query.account {
            matching[kSecAttrAccount] = account.securityValue
        }

        if let service = query.service {
            matching[kSecAttrService] = service.securityValue
        }

        var value: CFTypeRef?
        try Self.withSecurityInvocation {
            return SecItemCopyMatching(matching as CFDictionary, &value)
        }

        if let value = value as? Value {
            return value
        } else if let value = value {
            Logger.systemKeychainInterface.error("Invalid query result type: \(type(of: value))")
            throw .internalError
        } else {
            Logger.systemKeychainInterface.error("Invalid success without result.")
            throw .internalError
        }
    }

    public nonisolated func insertValue(_ value: Value, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError) {
        var attributes: Dictionary<CFString, CFTypeRef> = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: kCFBooleanTrue,
            kSecValueData: value.securityValue,
        ]

        Self.apply(modifications, to: &attributes)

        try Self.withSecurityInvocation {
            return SecItemAdd(attributes as CFDictionary, nil)
        }
    }

    public nonisolated func updateValue(_ value: Value, forQuery query: borrowing KeychainQuery, attributes modifications: borrowing KeychainAttributes.Modifications) throws(KeychainInterfaceError) {
        var matching: Dictionary<CFString, CFTypeRef> = [
            kSecAttrSynchronizable: query.synchronizable.securityValue,
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: kCFBooleanTrue,
        ]

        if let accessGroup = query.accessGroup {
            matching[kSecAttrAccessGroup] = accessGroup.securityValue
        }

        if let account = query.account {
            matching[kSecAttrAccount] = account.securityValue
        }

        if let service = query.service {
            matching[kSecAttrService] = service.securityValue
        }

        var attributes: Dictionary<CFString, CFTypeRef> = [
            kSecValueData: value.securityValue,
        ]

        Self.apply(modifications, to: &attributes)

        try Self.withSecurityInvocation {
            return SecItemUpdate(matching as CFDictionary, attributes as CFDictionary)
        }
    }

    public nonisolated func removeValue(forQuery query: borrowing KeychainQuery) throws(KeychainInterfaceError) {
        var matching: Dictionary<CFString, CFTypeRef> = [
            kSecAttrSynchronizable: query.synchronizable.securityValue,
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: kCFBooleanTrue,
        ]

        if let accessGroup = query.accessGroup {
            matching[kSecAttrAccessGroup] = accessGroup.securityValue
        }

        if let account = query.account {
            matching[kSecAttrAccount] = account.securityValue
        }

        if let service = query.service {
            matching[kSecAttrService] = service.securityValue
        }

        try Self.withSecurityInvocation {
            return SecItemDelete(matching as CFDictionary)
        }
    }
}

extension SystemKeychainInterface: ObservableKeychainInterfaceProtocol {

    // MARK: - ObservableKeychainInterfaceProtocol Conformance

    var observationRegistrar: ObservationRegistrar {
        return Self.sharedObservationRegistrar
    }
}
