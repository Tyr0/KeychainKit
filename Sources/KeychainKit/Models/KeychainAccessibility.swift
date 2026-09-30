
internal import CoreFoundation
internal import Security

/// When a keychain item's data can be read.
///
/// Variants ending in `ThisDeviceOnly` are never restored to another device from a
/// backup, and cannot be used by synchronizable items.
///
/// - SeeAlso: kSecAttrAccessible
public enum KeychainAccessibility: Equatable, Sendable {

    /// Readable only while the device is unlocked.
    ///
    /// The Security framework's default for new items.
    ///
    /// - SeeAlso: kSecAttrAccessibleWhenUnlocked
    case whenUnlocked

    /// Readable only while the device is unlocked, and never leaves this device.
    ///
    /// - SeeAlso: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    case whenUnlockedThisDeviceOnly

    /// Readable from the first unlock after a restart until the next restart.
    ///
    /// Suited to items read in the background while the device is locked.
    ///
    /// - SeeAlso: kSecAttrAccessibleAfterFirstUnlock
    case afterFirstUnlock

    /// Readable from the first unlock after a restart until the next restart, and never
    /// leaves this device.
    ///
    /// - SeeAlso: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly
}

extension KeychainAccessibility: CustomStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        switch self {
        case .afterFirstUnlock:
            return ".afterFirstUnlock"
        case .afterFirstUnlockThisDeviceOnly:
            return ".afterFirstUnlockThisDeviceOnly"
        case .whenUnlocked:
            return ".whenUnlocked"
        case .whenUnlockedThisDeviceOnly:
            return ".whenUnlockedThisDeviceOnly"
        }
    }
}

extension KeychainAccessibility: CustomDebugStringConvertible {

    /// A textual representation of this instance, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .afterFirstUnlock:
            return "\(_typeName(Self.self)).afterFirstUnlock"
        case .afterFirstUnlockThisDeviceOnly:
            return "\(_typeName(Self.self)).afterFirstUnlockThisDeviceOnly"
        case .whenUnlocked:
            return "\(_typeName(Self.self)).whenUnlocked"
        case .whenUnlockedThisDeviceOnly:
            return "\(_typeName(Self.self)).whenUnlockedThisDeviceOnly"
        }
    }
}

extension KeychainAccessibility: SecurityRepresentable {

    var securityValue: CFString {
        switch self {
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
    }
}
