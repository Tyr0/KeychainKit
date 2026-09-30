import Security
import Testing

@testable import KeychainKit

@Suite
struct KeychainQueryTests {

    private enum Constants {

        static let query = KeychainQuery(
            accessGroup: "TestAccessGroup",
            account: "TestAccount",
            service: "TestService",
            synchronizable: .explicit(true)
        )
    }

    @Test
    func testInitialization() async throws {
        let query = Constants.query
        #expect(query.accessGroup == "TestAccessGroup")
        #expect(query.account == "TestAccount")
        #expect(query.service == "TestService")
        #expect(query.synchronizable == .explicit(true))
    }

    @Test
    func testInitialization_DefaultSynchronizable_MatchesNonSynchronizableOnly() async throws {
        let query = KeychainQuery(accessGroup: nil, account: nil, service: nil)
        #expect(query.synchronizable == .explicit(false))
    }

    @Test(arguments: [
        (Constants.query, "KeychainQuery(account: Optional(\"TestAccount\"), service: Optional(\"TestService\"))"),
        (KeychainQuery(accessGroup: nil, account: nil, service: nil), "KeychainQuery(account: nil, service: nil)"),
    ])
    func testDescription(query: KeychainQuery, expectedDescription: String) async throws {
        #expect(query.description == expectedDescription)
    }

    @Test(arguments: [
        (Constants.query, "KeychainKit.KeychainQuery(accessGroup: Optional(\"TestAccessGroup\"), account: Optional(\"TestAccount\"), service: Optional(\"TestService\"), synchronizable: .explicit(true))"),
        (KeychainQuery(accessGroup: nil, account: nil, service: nil, synchronizable: .any), "KeychainKit.KeychainQuery(accessGroup: nil, account: nil, service: nil, synchronizable: .any)"),
    ])
    func testDebugDescription(query: KeychainQuery, expectedDescription: String) async throws {
        #expect(query.debugDescription == expectedDescription)
    }

    @Test
    func testEquatable_True() async throws {
        let lhs = Constants.query
        let rhs = KeychainQuery(accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService", synchronizable: .explicit(true))
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test(arguments: [
        KeychainQuery(accessGroup: nil, account: "TestAccount", service: "TestService", synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "OtherAccessGroup", account: "TestAccount", service: "TestService", synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: nil, service: "TestService", synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: "OtherAccount", service: "TestService", synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: "TestAccount", service: nil, synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: "TestAccount", service: "OtherService", synchronizable: .explicit(true)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService", synchronizable: .explicit(false)),
        KeychainQuery(accessGroup: "TestAccessGroup", account: "TestAccount", service: "TestService", synchronizable: .any),
    ])
    func testEquatable_False(rhs: KeychainQuery) async throws {
        let lhs = Constants.query
        #expect(lhs != rhs)
        #expect(rhs != lhs)
    }

    @Suite
    struct SynchronizableTests {

        @Test(arguments: [
            (KeychainQuery.Synchronizable.any, ".any"),
            (KeychainQuery.Synchronizable.explicit(true), ".explicit(true)"),
            (KeychainQuery.Synchronizable.explicit(false), ".explicit(false)"),
        ])
        func testDescription(synchronizable: KeychainQuery.Synchronizable, expectedDescription: String) async throws {
            #expect(synchronizable.description == expectedDescription)
        }

        @Test
        func testBooleanLiteral() async throws {
            let synchronizableTrue: KeychainQuery.Synchronizable = true
            let synchronizableFalse: KeychainQuery.Synchronizable = false
            #expect(synchronizableTrue == .explicit(true))
            #expect(synchronizableFalse == .explicit(false))
        }

        @Test(arguments: [
            (KeychainQuery.Synchronizable.any, KeychainQuery.Synchronizable.any),
            (KeychainQuery.Synchronizable.explicit(true), KeychainQuery.Synchronizable.explicit(true)),
            (KeychainQuery.Synchronizable.explicit(false), KeychainQuery.Synchronizable.explicit(false)),
        ])
        func testEquatable_True(lhs: KeychainQuery.Synchronizable, rhs: KeychainQuery.Synchronizable) async throws {
            #expect(lhs == rhs)
            #expect(rhs == lhs)
        }

        @Test(arguments: [
            (KeychainQuery.Synchronizable.any, KeychainQuery.Synchronizable.explicit(true)),
            (KeychainQuery.Synchronizable.any, KeychainQuery.Synchronizable.explicit(false)),
            (KeychainQuery.Synchronizable.explicit(true), KeychainQuery.Synchronizable.explicit(false)),
        ])
        func testEquatable_False(lhs: KeychainQuery.Synchronizable, rhs: KeychainQuery.Synchronizable) async throws {
            #expect(lhs != rhs)
            #expect(rhs != lhs)
        }

        @Test
        func testSecurityValue() async throws {
            #expect(CFEqual(KeychainQuery.Synchronizable.any.securityValue, kSecAttrSynchronizableAny))
            #expect(CFEqual(KeychainQuery.Synchronizable.explicit(true).securityValue, kCFBooleanTrue))
            #expect(CFEqual(KeychainQuery.Synchronizable.explicit(false).securityValue, kCFBooleanFalse))
        }
    }
}
