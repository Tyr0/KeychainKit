
import Foundation

internal import os.log
internal import Security

public struct SystemKeychainInterface: KeychainInterfaceProtocol {

    // MARK: - Lifecycle Functions

    public init() {
    }

    // MARK: - Private Functions

    private static func withSecurityInvocation(perform body: () -> OSStatus) throws(KeychainError) {
        let status = body()
        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw .duplicateItem
        case errSecItemNotFound:
            throw .itemNotFound
        case errSecInteractionNotAllowed:
            throw .interactionNotAllowed
        default:
            throw .unknownError(status)
        }
    }

    // MARK: - KeychainInterfaceProtocol Conformance

    public nonisolated func value(forKey key: Key) throws(KeychainError) -> Value? {
        let query: Dictionary<CFString, Any> = [
            kSecAttrAccount: key.account,
            kSecAttrService: key.service,
            kSecClass: kSecClassGenericPassword,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecUseDataProtectionKeychain: true,
        ]

        do throws(KeychainError) {
            var value: CFTypeRef?
            try Self.withSecurityInvocation {
                return SecItemCopyMatching(query as CFDictionary, &value)
            }

            if let value = value as? Data {
                return value
            } else if let value = value {
                Logger.systemKeychainInterface.error("Invalid query result type: \(type(of: value))")
                throw .itemNotFound
            } else {
                Logger.systemKeychainInterface.error("Invalid success without result.")
                throw .itemNotFound
            }
        } catch .itemNotFound {
            return nil
        }
    }

    public nonisolated func insertValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        let attributes: Dictionary<CFString, Any> = [
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrAccount: key.account,
            kSecAttrService: key.service,
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: value,
        ]

        try Self.withSecurityInvocation {
            return SecItemAdd(attributes as CFDictionary, nil)
        }
    }

    public nonisolated func updateValue(_ value: Value, forKey key: Key) throws(KeychainError) {
        let query: Dictionary<CFString, Any> = [
            kSecAttrAccount: key.account,
            kSecAttrService: key.service,
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
        ]

        let attributes: Dictionary<CFString, Any> = [
            kSecValueData: value,
        ]

        try Self.withSecurityInvocation {
            return SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        }
    }

    public nonisolated func removeValue(forKey key: Key) throws(KeychainError) {
        let query: Dictionary<CFString, Any> = [
            kSecAttrAccount: key.account,
            kSecAttrService: key.service,
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
        ]

        do throws(KeychainError) {
            try Self.withSecurityInvocation {
                return SecItemDelete(query as CFDictionary)
            }
        } catch .itemNotFound {
            return
        }
    }
}
