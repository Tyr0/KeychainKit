import Security
import Testing

@testable import KeychainKit

@Suite
struct KeychainAccessibilityTests {

    @Test(arguments: [
        (KeychainAccessibility.afterFirstUnlock, ".afterFirstUnlock"),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, ".afterFirstUnlockThisDeviceOnly"),
        (KeychainAccessibility.whenUnlocked, ".whenUnlocked"),
        (KeychainAccessibility.whenUnlockedThisDeviceOnly, ".whenUnlockedThisDeviceOnly"),
    ])
    func testDescription(accessibility: KeychainAccessibility, expectedDescription: String) async throws {
        #expect(accessibility.description == expectedDescription)
    }

    @Test(arguments: [
        (KeychainAccessibility.afterFirstUnlock, "KeychainKit.KeychainAccessibility.afterFirstUnlock"),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, "KeychainKit.KeychainAccessibility.afterFirstUnlockThisDeviceOnly"),
        (KeychainAccessibility.whenUnlocked, "KeychainKit.KeychainAccessibility.whenUnlocked"),
        (KeychainAccessibility.whenUnlockedThisDeviceOnly, "KeychainKit.KeychainAccessibility.whenUnlockedThisDeviceOnly"),
    ])
    func testDebugDescription(accessibility: KeychainAccessibility, expectedDescription: String) async throws {
        #expect(accessibility.debugDescription == expectedDescription)
    }

    @Test(arguments: [
        (KeychainAccessibility.afterFirstUnlock, KeychainAccessibility.afterFirstUnlock),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, KeychainAccessibility.afterFirstUnlockThisDeviceOnly),
        (KeychainAccessibility.whenUnlocked, KeychainAccessibility.whenUnlocked),
        (KeychainAccessibility.whenUnlockedThisDeviceOnly, KeychainAccessibility.whenUnlockedThisDeviceOnly),
    ])
    func testEquatable_True(lhs: KeychainAccessibility, rhs: KeychainAccessibility) async throws {
        #expect(lhs == rhs)
        #expect(rhs == lhs)
    }

    @Test(arguments: [
        (KeychainAccessibility.afterFirstUnlock, KeychainAccessibility.afterFirstUnlockThisDeviceOnly),
        (KeychainAccessibility.afterFirstUnlock, KeychainAccessibility.whenUnlocked),
        (KeychainAccessibility.afterFirstUnlock, KeychainAccessibility.whenUnlockedThisDeviceOnly),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, KeychainAccessibility.whenUnlocked),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, KeychainAccessibility.whenUnlockedThisDeviceOnly),
        (KeychainAccessibility.whenUnlocked, KeychainAccessibility.whenUnlockedThisDeviceOnly),
    ])
    func testEquatable_False(lhs: KeychainAccessibility, rhs: KeychainAccessibility) async throws {
        #expect(lhs != rhs)
        #expect(rhs != lhs)
    }

    @Test(arguments: [
        (KeychainAccessibility.afterFirstUnlock, kSecAttrAccessibleAfterFirstUnlock as String),
        (KeychainAccessibility.afterFirstUnlockThisDeviceOnly, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String),
        (KeychainAccessibility.whenUnlocked, kSecAttrAccessibleWhenUnlocked as String),
        (KeychainAccessibility.whenUnlockedThisDeviceOnly, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String),
    ])
    func testSecurityValue(accessibility: KeychainAccessibility, securityValue: String) async throws {
        #expect(accessibility.securityValue == securityValue as CFString)
    }
}
