
/// A typed keychain item definition for interfacing with a ``KeychainProtocol``.
///
/// Conform a type for each kind of secret, then read and write it per account:
///
/// ```swift
/// enum AuthTokenItem: KeychainItemProtocol {
///
///     static let defaultValue: Optional<String> = nil
///
///     static let service: String = "com.example.auth-token"
/// }
///
/// let keychain = Keychain()
/// keychain[AuthTokenItem.self, account: userID] = "abc123"
/// ```
///
/// Each item is stored as a generic password whose service is ``service`` and whose
/// account is the account passed to the ``KeychainProtocol`` method.
public protocol KeychainItemProtocol: Sendable {

    /// The value stored for this item.
    associatedtype Value: KeychainRepresentable

    /// The value returned when no item exists, including after the item is removed.
    ///
    /// Reading the default value does not persist it.
    static var defaultValue: Value { get }

    /// The data protection applied when the item is first inserted.
    ///
    /// Defaults to ``KeychainPolicy/default``. The policy's accessibility is applied only
    /// on insertion; updating an existing item does not change its protection.
    static var policy: KeychainPolicy { get }

    /// The service identifying this item in the keychain.
    ///
    /// - Important: Use a stable service unique to this item type. Types that share a
    ///   service address the same stored items, and changing a service does not migrate
    ///   items stored under the previous one.
    static var service: String { get }
}

extension KeychainItemProtocol {

    /// The default data protection: ``KeychainPolicy/default``.
    public static var policy: KeychainPolicy {
        return .default
    }
}
