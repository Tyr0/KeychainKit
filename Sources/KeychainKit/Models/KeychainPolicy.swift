internal import CoreFoundation
internal import Security

/// The data protection applied to a keychain item when it is inserted.
///
/// ``default`` is currently the only policy: readable only while the device is
/// unlocked, never synchronized through iCloud Keychain, and never restored to another
/// device from a backup.
///
/// A policy applies when an item is first inserted. Updating an existing item does not
/// change its protection, so items inserted under a different policy keep theirs.
public struct KeychainPolicy: Equatable, Sendable {

    /// Readable only while the device is unlocked.
    ///
    /// Items use `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` and are not
    /// synchronizable. Reads while the device is locked fail with
    /// ``KeychainError/interactionNotAllowed``.
    public static var `default`: KeychainPolicy {
        KeychainPolicy(id: "default")
    }

    // MARK: - Properties

    internal let id: String

    internal var accessibility: KeychainAccessibility {
        return .whenUnlocked
    }

    internal var synchronizable: Bool {
        return false
    }
}

extension KeychainPolicy: CustomStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        return "\(_typeName(Self.self, qualified: false))(id: \(self.id))"
    }
}

extension KeychainPolicy: CustomDebugStringConvertible {

    /// A textual representation of this instance, including its protection, suitable for debugging.
    public var debugDescription: String {
        return "\(_typeName(Self.self))(id: \(self.id), accessibility: \(self.accessibility), synchronizable: \(self.synchronizable))"
    }
}
