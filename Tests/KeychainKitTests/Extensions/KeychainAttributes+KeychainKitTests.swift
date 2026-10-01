import KeychainKit

extension KeychainAttributes {

    private enum Constants {
        static let defaultAccessGroup: String = "com.calderone.KeychainKitTests.AccessGroup"
        static let defaultAccessibility: KeychainAccessibility = .whenUnlocked
        static let defaultAccount: String = ""
        static let defaultService: String = ""
        static let defaultSynchronizable: Bool = false
    }

    static func resolving(query: KeychainQuery) -> Self {
        self.init(
            accessibility: Constants.defaultAccessibility,
            accessGroup: query.accessGroup ?? Constants.defaultAccessGroup,
            account: query.account ?? Constants.defaultAccount,
            service: query.service ?? Constants.defaultService,
            synchronizable: query.synchronizable == .explicit(true),
        )
    }

    static func resolving(modifications: KeychainAttributes.Modifications) -> Self {
        self.init(
            accessibility: modifications.accessibility ?? Constants.defaultAccessibility,
            accessGroup: modifications.accessGroup ?? Constants.defaultAccessGroup,
            account: modifications.account ?? Constants.defaultAccount,
            service: modifications.service ?? Constants.defaultService,
            synchronizable: modifications.synchronizable ?? Constants.defaultSynchronizable,
        )
    }
}
