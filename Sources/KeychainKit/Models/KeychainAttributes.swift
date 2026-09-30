
/// The attributes of a stored generic password item.
///
/// An item's access group, account, service, and synchronizable flag together form its
/// primary key: no two items may share all four. Its accessibility controls when the
/// item's data can be read, and does not form part of the key.
///
/// Use ``Modifications`` to describe the attributes written by an insert or update.
public struct KeychainAttributes: Equatable, Hashable, Sendable {

    /// Attributes written to a generic password item by an insert or update.
    ///
    /// Attributes left `nil` are omitted. On insert, the store applies its defaults: an
    /// empty account and service, the app's first access group, not synchronizable, and
    /// ``KeychainAccessibility/whenUnlocked``. On update, the stored value is unchanged.
    public struct Modifications: Equatable, Sendable {

        // MARK: - Properties

        /// When the item's data can be read, or `nil` to leave it unchanged.
        ///
        /// - SeeAlso: kSecAttrAccessible
        public var accessibility: KeychainAccessibility?

        /// The access group the item belongs to, or `nil` to leave it unchanged.
        ///
        /// Must be one of the app's access groups.
        ///
        /// - SeeAlso: kSecAttrAccessGroup
        public var accessGroup: String?

        /// The account name of the item, or `nil` to leave it unchanged.
        ///
        /// - SeeAlso: kSecAttrAccount
        public var account: String?

        /// The service the item belongs to, or `nil` to leave it unchanged.
        ///
        /// - SeeAlso: kSecAttrService
        public var service: String?

        /// Whether the item syncs through iCloud Keychain, or `nil` to leave it unchanged.
        ///
        /// A synchronizable item may not use a `ThisDeviceOnly` accessibility.
        ///
        /// - SeeAlso: kSecAttrSynchronizable
        public var synchronizable: Bool?

        // MARK: - Lifecycle Functions

        /// Creates attributes to write, omitting any left `nil`.
        public init(accessibility: KeychainAccessibility? = nil, accessGroup: String? = nil, account: String? = nil, service: String? = nil, synchronizable: Bool? = nil) {
            self.accessibility = accessibility
            self.accessGroup = accessGroup
            self.account = account
            self.service = service
            self.synchronizable = synchronizable
        }
    }

    // MARK: - Properties

    /// When the item's data can be read.
    ///
    /// - SeeAlso: kSecAttrAccessible
    public var accessibility: KeychainAccessibility

    /// The access group the item belongs to.
    ///
    /// - SeeAlso: kSecAttrAccessGroup
    public var accessGroup: String

    /// The account name of the item.
    ///
    /// - SeeAlso: kSecAttrAccount
    public var account: String

    /// The service the item belongs to.
    ///
    /// - SeeAlso: kSecAttrService
    public var service: String

    /// Whether the item syncs through iCloud Keychain.
    ///
    /// - SeeAlso: kSecAttrSynchronizable
    public var synchronizable: Bool

    // MARK: - Lifecycle Functions

    /// Creates the attributes of a stored item.
    public init(accessibility: KeychainAccessibility, accessGroup: String, account: String, service: String, synchronizable: Bool) {
        self.accessibility = accessibility
        self.accessGroup = accessGroup
        self.account = account
        self.service = service
        self.synchronizable = synchronizable
    }
}
