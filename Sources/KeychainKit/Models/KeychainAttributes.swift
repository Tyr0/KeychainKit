
import Foundation

public struct KeychainAttributes: Equatable, Hashable, Sendable {

    private static func makeDefaultServiceName() -> String {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            return bundleIdentifier
        } else {
            return ProcessInfo.processInfo.processName
        }
    }

    public static let defaultService: String = KeychainAttributes.makeDefaultServiceName()

    // MARK: - Properties

    public let account: String

    public let service: String

    // MARK: - Lifecycle Functions

    public init(account: String, service: String = KeychainAttributes.defaultService) {
        self.account = account
        self.service = service
    }
}

extension KeychainAttributes: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(account: value)
    }
}
