import Darwin

internal import Security

/// A Security framework status code reported by a ``KeychainInterfaceProtocol``.
///
/// Known statuses are available as static members and can be matched directly:
///
/// ```swift
/// do {
///     try interface.removeValue(forQuery: query)
/// } catch .itemNotFound {
///     // Nothing to remove.
/// } catch {
///     // Any other status, available as `error.rawValue`.
/// }
/// ```
///
/// Any other status is represented by its raw `OSStatus` value.
public struct KeychainInterfaceError: Equatable, Error, Hashable, RawRepresentable {

    /// The Security framework status code.
    public typealias RawValue = OSStatus

    // MARK: - Static Properties

    /// An item with the same primary key already exists.
    ///
    /// - SeeAlso: errSecDuplicateItem
    public static let duplicateItem = KeychainInterfaceError(rawValue: errSecDuplicateItem)

    /// The keychain is unavailable, typically because the device is locked.
    ///
    /// - SeeAlso: errSecInteractionNotAllowed
    public static let interactionNotAllowed = KeychainInterfaceError(rawValue: errSecInteractionNotAllowed)

    /// The store reported success but returned an unexpected result.
    ///
    /// - SeeAlso: errSecInternalError
    public static let internalError = KeychainInterfaceError(rawValue: errSecInternalError)

    /// No item matches the query.
    ///
    /// - SeeAlso: errSecItemNotFound
    public static let itemNotFound = KeychainInterfaceError(rawValue: errSecItemNotFound)

    /// The process lacks the entitlements required to access the keychain.
    ///
    /// - SeeAlso: errSecMissingEntitlement
    public static let missingEntitlement = KeychainInterfaceError(rawValue: errSecMissingEntitlement)

    // MARK: - Properties

    /// The Security framework status code.
    public let rawValue: RawValue

    // MARK: - Lifecycle Functions

    /// Creates an error from a Security framework status code.
    public init(_ rawValue: OSStatus) {
        self.rawValue = rawValue
    }

    /// Creates an error from a Security framework status code.
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}

extension KeychainInterfaceError: CustomStringConvertible {

    /// A textual representation of this instance, including the status code.
    public var description: String {
        return "\(_typeName(Self.self, qualified: false))(\(self.rawValue))"
    }
}

extension KeychainInterfaceError: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        if let message = SecCopyErrorMessageString(self.rawValue, nil) {
            return "\(_typeName(Self.self))(\(self.rawValue), message: \(message))"
        } else {
            return "\(_typeName(Self.self))(\(self.rawValue))"
        }
    }
}
