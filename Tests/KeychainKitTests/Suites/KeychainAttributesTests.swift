import Testing

@testable import KeychainKit

@Suite
struct KeychainAttributesTests {

    private enum Constants {

        static let attributes = KeychainAttributes(
            accessibility: .whenUnlocked,
            accessGroup: "TestAccessGroup",
            account: "TestAccount",
            service: "TestService",
            synchronizable: false
        )
    }

    @Test
    func testInitialization() async throws {
        let attributes = Constants.attributes
        #expect(attributes.accessibility == .whenUnlocked)
        #expect(attributes.accessGroup == "TestAccessGroup")
        #expect(attributes.account == "TestAccount")
        #expect(attributes.service == "TestService")
        #expect(attributes.synchronizable == false)
    }

    @Test
    func testEquatable_True() async throws {
        let lhs = Constants.attributes
        let rhs = KeychainAttributes(
            accessibility: .whenUnlocked,
            accessGroup: "TestAccessGroup",
            account: "TestAccount",
            service: "TestService",
            synchronizable: false
        )
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test(arguments: [
        KeychainAttributes(accessibility: .afterFirstUnlock, accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService", synchronizable: false),
        KeychainAttributes(accessibility: .whenUnlocked, accessGroup: "OtherAccessGroup", account: "TestAccount", service: "TestService", synchronizable: false),
        KeychainAttributes(accessibility: .whenUnlocked, accessGroup: "TestAccessGroup", account: "OtherAccount", service: "TestService", synchronizable: false),
        KeychainAttributes(accessibility: .whenUnlocked, accessGroup: "TestAccessGroup", account: "TestAccount", service: "OtherService", synchronizable: false),
        KeychainAttributes(accessibility: .whenUnlocked, accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService", synchronizable: true),
    ])
    func testEquatable_False(rhs: KeychainAttributes) async throws {
        let lhs = Constants.attributes
        #expect(lhs != rhs)
        #expect(rhs != lhs)
    }

    @Suite
    struct ModificationsTests {

        @Test
        func testInit_Default() async throws {
            let modifications = KeychainAttributes.Modifications()
            #expect(modifications.accessibility == nil)
            #expect(modifications.accessGroup == nil)
            #expect(modifications.account == nil)
            #expect(modifications.service == nil)
            #expect(modifications.synchronizable == nil)
        }

        @Test
        func testInitialization() async throws {
            let modifications = KeychainAttributes.Modifications(
                accessibility: .afterFirstUnlock,
                accessGroup: "TestAccessGroup",
                account: "TestAccount",
                service: "TestService",
                synchronizable: true
            )
            #expect(modifications.accessibility == .afterFirstUnlock)
            #expect(modifications.accessGroup == "TestAccessGroup")
            #expect(modifications.account == "TestAccount")
            #expect(modifications.service == "TestService")
            #expect(modifications.synchronizable == true)
        }

        @Test
        func testEquatable_True() async throws {
            let lhs = KeychainAttributes.Modifications(account: "TestAccount", service: "TestService")
            let rhs = KeychainAttributes.Modifications(account: "TestAccount", service: "TestService")
            #expect(lhs == rhs)
            #expect(rhs == lhs)
        }

        @Test(arguments: [
            KeychainAttributes.Modifications(),
            KeychainAttributes.Modifications(accessibility: .whenUnlocked, account: "TestAccount", service: "TestService"),
            KeychainAttributes.Modifications(accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService"),
            KeychainAttributes.Modifications(account: "OtherAccount", service: "TestService"),
            KeychainAttributes.Modifications(account: "TestAccount", service: "OtherService"),
            KeychainAttributes.Modifications(account: "TestAccount", service: "TestService", synchronizable: false),
        ])
        func testEquatable_False(rhs: KeychainAttributes.Modifications) async throws {
            let lhs = KeychainAttributes.Modifications(account: "TestAccount", service: "TestService")
            #expect(lhs != rhs)
            #expect(rhs != lhs)
        }
    }
}
