internal import os.log

/// A property wrapper type that reflects a value from a ``KeychainItemProtocol``.
@propertyWrapper
public struct KeychainItem<Keychain, KeychainItem>: Sendable where Keychain: KeychainProtocol, KeychainItem: KeychainItemProtocol {

    /// The value represented by the keychain item definition.
    public typealias Value = KeychainItem.Value

    // MARK: - Properties

    /// The keychain used to read and write the item.
    public let keychain: Keychain

    /// The account the item is stored under.
    public let account: String

    /// The keychain item value, or the item's default when reading fails or no value exists.
    public var wrappedValue: Value {
        get {
            do {
                return try self.keychain.value(forItem: KeychainItem.self, account: self.account)
            } catch {
                Logger.keychainItem.error("Attempted to read \(_typeName(KeychainItem.self)) but received error instead: \(error)")
            }

            return KeychainItem.defaultValue
        }
        nonmutating set {
            do {
                try self.keychain.updateValue(newValue, forItem: KeychainItem.self, account: self.account)
            } catch {
                Logger.keychainItem.error("Attempted to update \(_typeName(KeychainItem.self)) but received error instead: \(error)")
            }
        }
    }

    // MARK: - Lifecycle Functions

    /// Creates a property for interfacing with a preference in the given preferences.
    ///
    /// - Parameters:
    ///   - item: The keychain item definition. May be inferred from the wrapper's type.
    ///   - keychain: The keychain used for reads and writes.
    ///   - account: The account the item is stored under.
    public init(_ item: KeychainItem.Type = KeychainItem.self, keychain: Keychain, account: String) {
        self.keychain = keychain
        self.account = account
    }
}

extension KeychainItem where Keychain == KeychainKit.Keychain<SystemKeychainInterface> {

    /// Creates a property for interfacing with a preference in ``Keychain``.
    ///
    /// - Parameters:
    ///   - item: The keychain item definition. May be inferred from the wrapper's type.
    ///   - keychain: The keychain used for reads and writes.
    ///   - account: The account the item is stored under.
    public init(_ item: KeychainItem.Type = KeychainItem.self, keychain: Keychain = .default, account: String) {
        self.keychain = keychain
        self.account = account
    }
}
