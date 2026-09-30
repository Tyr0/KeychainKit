
import Foundation

/// An error raised by a ``KeychainProtocol`` operation.
///
/// Catch a specific Security failure with its static member, and conversion failures
/// with their cases:
///
/// ```swift
/// do {
///     let token = try keychain.value(forItem: AuthTokenItem.self, account: userID)
/// } catch .interactionNotAllowed {
///     // The device is locked; the item still exists. Retry after unlock.
/// } catch .decodingError {
///     // The stored data is not a valid value.
/// } catch {
///     // Any other failure.
/// }
/// ```
///
/// Swift does not treat a list of `catch` clauses as exhaustive for typed throws, so end
/// with an unconditional `catch`, or `switch` over the caught error.
public enum KeychainError: Error, Sendable {

    /// The stored data could not be converted to the item's value.
    ///
    /// The item is left unchanged; writing a new value replaces it.
    case decodingError(DecodingError)

    /// The value could not be converted to data for storage.
    ///
    /// The store is not modified.
    ///
    /// - Important: `EncodingError.invalidValue(_:_:)` carries the value that failed to
    ///   encode, which may be the secret itself. Take care when logging or reporting it.
    case encodingError(EncodingError)

    /// A Security framework failure, carrying the underlying status code.
    case securityError(_ underlyingError: KeychainInterfaceError)
}

extension KeychainError {

    /// The keychain is unavailable, typically because the device is locked.
    ///
    /// The item still exists; retry after the device is unlocked.
    public static let interactionNotAllowed = KeychainError.securityError(.interactionNotAllowed)

    /// The process lacks the entitlements required to access the keychain.
    ///
    /// On macOS the data-protection keychain requires a signed app with an application
    /// identifier; unsigned processes — including Swift package test runners — fail with
    /// this error.
    public static let missingEntitlement = KeychainError.securityError(.missingEntitlement)

    /// Matches Security failures by status code, enabling `catch .interactionNotAllowed`.
    ///
    /// `KeychainError` is not `Equatable` because its conversion errors are not. This
    /// operator lets the static members above be used as patterns. Only
    /// ``securityError(_:)`` values match; match the other cases by case name.
    public static func ~= (pattern: KeychainError, value: KeychainError) -> Bool {
        switch (pattern, value) {
        case let (.securityError(patternError), .securityError(valueError)):
            return patternError == valueError
        default:
            return false
        }
    }
}

extension KeychainError: CustomStringConvertible {

    /// A textual representation of this instance.
    ///
    /// Conversion errors are summarized without their underlying error, so the
    /// description never includes a stored value.
    public var description: String {
        switch self {
        case .decodingError:
            return ".decodingError"
        case .encodingError:
            return ".encodingError"
        case .securityError(let underlyingError):
            return ".securityError(\(underlyingError))"
        }
    }
}

extension KeychainError: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .decodingError(let underlyingError):
            return ".decodingError(\(underlyingError))"
        case .encodingError(let underlyingError):
            return ".encodingError(\(underlyingError))"
        case .securityError(let underlyingError):
            return ".securityError(\(underlyingError))"
        }
    }
}
