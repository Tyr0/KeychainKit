
import Foundation

/// Search criteria selecting generic password items.
///
/// A generic password is uniquely identified by its access group, account, service,
/// and synchronizable flag. A `nil` field matches any value, so a query that sets all
/// four selects at most one item.
///
/// - SeeAlso: https://developer.apple.com/documentation/security/ksecclassgenericpassword
public struct KeychainQuery: Equatable, Hashable, Sendable {

    /// Whether a query matches synchronizable items.
    ///
    /// - SeeAlso: kSecAttrSynchronizable
    public enum Synchronizable: Equatable, Hashable, Sendable {

        /// Matches both synchronizable and non-synchronizable items.
        ///
        /// - SeeAlso: kSecAttrSynchronizableAny
        case any

        /// Matches only items whose synchronizable flag equals the value.
        case explicit(Bool)
    }

    // MARK: - Properties

    /// The access group to search, or `nil` to search every access group the app belongs to.
    ///
    /// - SeeAlso: kSecAttrAccessGroup
    public let accessGroup: String?

    /// The account name of the item, or `nil` to match any account.
    ///
    /// - SeeAlso: kSecAttrAccount
    public let account: String?

    /// The service the item belongs to, or `nil` to match any service.
    ///
    /// - SeeAlso: kSecAttrService
    public let service: String?

    /// Whether to match synchronizable items.
    ///
    /// - SeeAlso: kSecAttrSynchronizable
    public let synchronizable: Synchronizable

    // MARK: - Lifecycle Functions

    /// Creates search criteria.
    ///
    /// - Parameters:
    ///   - accessGroup: The access group to search, or `nil` for every group the app belongs to.
    ///   - account: The account name of the item, or `nil` to match any account.
    ///   - service: The service the item belongs to, or `nil` to match any service.
    ///   - synchronizable: Whether to match synchronizable items. Defaults to
    ///     non-synchronizable items only, matching the Security framework's default.
    public init(accessGroup: String?, account: String?, service: String?, synchronizable: Synchronizable = .explicit(false)) {
        self.accessGroup = accessGroup
        self.account = account
        self.service = service
        self.synchronizable = synchronizable
    }
}

extension KeychainQuery: CustomStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        return "\(_typeName(Self.self, qualified: false))(account: \(String(describing: self.account)), service: \(String(describing: self.service)))"
    }
}

extension KeychainQuery: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        return "\(_typeName(Self.self))(accessGroup: \(String(describing: self.accessGroup)), account: \(String(describing: self.account)), service: \(String(describing: self.service)), synchronizable: \(self.synchronizable))"
    }
}

extension KeychainQuery.Synchronizable: CustomStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        switch self {
        case .any:
            return ".any"
        case .explicit(let value):
            return ".explicit(\(value))"
        }
    }
}

extension KeychainQuery.Synchronizable: ExpressibleByBooleanLiteral {

    /// Creates a value matching only items whose synchronizable flag equals the literal.
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .explicit(value)
    }
}

extension KeychainQuery.Synchronizable: SecurityRepresentable {

    var securityValue: CFTypeRef {
        switch self {
        case .any:
            return kSecAttrSynchronizableAny
        case .explicit(let synchronizable):
            return synchronizable.securityValue
        }
    }
}
