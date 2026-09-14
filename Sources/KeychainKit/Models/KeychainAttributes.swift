
import Foundation

/// The attributes uniquely identifying a keychain item.
///
/// A generic password item is keyed by its account and service pair. The service
/// defaults to ``defaultService``, so distinct apps — and distinct services within an
/// app — address disjoint items even when their account names collide.
///
/// A string literal produces attributes whose account is the literal and whose service
/// is the default.
public struct KeychainAttributes: Equatable, Hashable, Sendable {

    private static func makeDefaultServiceName() -> String {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return bundleIdentifier
        } else {
            return ProcessInfo.processInfo.processName
        }
    }

    /// The service used when none is specified: the main bundle's identifier, or the
    /// process name when unavailable (e.g. in command-line tools).
    public static let defaultService: String = KeychainAttributes.makeDefaultServiceName()

    // MARK: - Properties

    /// The account name of the item.
    ///
    /// - Seealso: kSecAttrAccount
    public let account: String

    /// The service the item belongs to.
    ///
    /// - Seealso: kSecAttrService
    public let service: String

    // MARK: - Lifecycle Functions

    /// Creates attributes for the given account and service.
    ///
    /// - Parameters:
    ///   - account: The account name of the item.
    ///   - service: The service the item belongs to; defaults to ``defaultService``.
    public init(account: String, service: String = KeychainAttributes.defaultService) {
        self.account = account
        self.service = service
    }
}

extension KeychainAttributes: CustomStringConvertible {

    /// A textual representation of this instance.
    public var description: String {
        return "<\(_typeName(Self.self)): account=\(self.account), service=\(self.service)>"
    }
}

extension KeychainAttributes: ExpressibleByStringLiteral {

    /// Creates attributes whose account is the literal and whose service is
    /// ``defaultService``.
    public init(stringLiteral value: String) {
        self.init(account: value)
    }
}
