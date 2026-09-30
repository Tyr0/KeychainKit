
import Testing

@testable import KeychainKit

@Suite
struct KeychainPolicyTests {

    @Test
    func testDefaultPolicy() async throws {
        let policy = KeychainPolicy.default
        #expect(policy.accessibility == .whenUnlocked)
        #expect(policy.synchronizable == false)
    }

    @Test(arguments: [
        (KeychainPolicy.default, "KeychainPolicy(id: default)")
    ])
    func testDescription(policy: KeychainPolicy, expectedDescription: String) async throws {
        #expect(policy.description == expectedDescription)
    }

    @Test(arguments: [
        (KeychainPolicy.default, "KeychainKit.KeychainPolicy(id: default, accessibility: .whenUnlocked, synchronizable: false)")
    ])
    func testDebugDescription(policy: KeychainPolicy, expectedDescription: String) async throws {
        #expect(policy.debugDescription == expectedDescription)
    }

    @Test(arguments: [
        (KeychainPolicy.default, KeychainPolicy.default),
    ])
    func testEquatable_True(lhs: KeychainPolicy, rhs: KeychainPolicy) async throws {
        #expect(lhs == rhs)
        #expect(rhs == lhs)
    }
}
