
import Foundation

/// An error raised by a keychain operation.
public enum KeychainError: Equatable, Error, Sendable {

    /// An item already exists for the key.
    case duplicateItem

    /// The keychain is unavailable, typically because the device is locked.
    ///
    /// The item still exists; retry after the device is unlocked.
    case interactionNotAllowed

    /// No item exists for the key.
    case itemNotFound

    /// The process lacks the entitlements required to access the keychain.
    ///
    /// On macOS the data-protection keychain requires a signed app with an application
    /// identifier; unsigned processes — including Swift package test runners — fail with
    /// this error.
    case missingEntitlement

    /// Any other Security framework failure, carrying the underlying status code.
    case unknownError(OSStatus)
}
