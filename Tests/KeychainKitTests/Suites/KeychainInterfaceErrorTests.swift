import Security
import Testing

@testable import KeychainKit

@Suite
struct KeychainInterfaceErrorTests {

    @Test(arguments: [
        (KeychainInterfaceError.duplicateItem, errSecDuplicateItem),
        (KeychainInterfaceError.interactionNotAllowed, errSecInteractionNotAllowed),
        (KeychainInterfaceError.internalError, errSecInternalError),
        (KeychainInterfaceError.itemNotFound, errSecItemNotFound),
        (KeychainInterfaceError.missingEntitlement, errSecMissingEntitlement),
    ])
    func testRawValue(error: KeychainInterfaceError, expectedRawValue: OSStatus) async throws {
        #expect(error.rawValue == expectedRawValue)
    }

    @Test(arguments: [errSecSuccess, errSecItemNotFound, errSecParam, OSStatus(12345)])
    func testInitialization_MatchesRawValueInit(rawValue: OSStatus) async throws {
        let error = KeychainInterfaceError(rawValue)
        #expect(error == KeychainInterfaceError(rawValue: rawValue))
        #expect(error.rawValue == rawValue)
    }

    @Test(arguments: [
        (KeychainInterfaceError.duplicateItem, "KeychainInterfaceError(-25299)"),
        (KeychainInterfaceError.itemNotFound, "KeychainInterfaceError(-25300)"),
        (KeychainInterfaceError(rawValue: errSecParam), "KeychainInterfaceError(-50)"),
    ])
    func testDescription(error: KeychainInterfaceError, expectedDescription: String) async throws {
        #expect(error.description == expectedDescription)
    }

    @Test(arguments: [
        (KeychainInterfaceError.duplicateItem, "KeychainKit.KeychainInterfaceError(-25299, message: "),
        (KeychainInterfaceError.itemNotFound, "KeychainKit.KeychainInterfaceError(-25300, message: "),
        (KeychainInterfaceError(rawValue: errSecParam), "KeychainKit.KeychainInterfaceError(-50, message: "),
    ])
    func testDebugDescription(error: KeychainInterfaceError, expectedPrefix: String) async throws {
        // The message text comes from the Security framework and may vary between OS releases.
        #expect(error.debugDescription.hasPrefix(expectedPrefix))
        #expect(error.debugDescription.hasSuffix(")"))
    }

    @Test(arguments: [
        (KeychainInterfaceError.duplicateItem, KeychainInterfaceError(rawValue: errSecDuplicateItem)),
        (KeychainInterfaceError.interactionNotAllowed, KeychainInterfaceError(rawValue: errSecInteractionNotAllowed)),
        (KeychainInterfaceError.internalError, KeychainInterfaceError(rawValue: errSecInternalError)),
        (KeychainInterfaceError.itemNotFound, KeychainInterfaceError(rawValue: errSecItemNotFound)),
        (KeychainInterfaceError.missingEntitlement, KeychainInterfaceError(rawValue: errSecMissingEntitlement)),
    ])
    func testEquatable_True(lhs: KeychainInterfaceError, rhs: KeychainInterfaceError) async throws {
        #expect(lhs == rhs)
        #expect(rhs == lhs)
        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test(arguments: [
        (KeychainInterfaceError.duplicateItem, KeychainInterfaceError.itemNotFound),
        (KeychainInterfaceError.interactionNotAllowed, KeychainInterfaceError.missingEntitlement),
        (KeychainInterfaceError.internalError, KeychainInterfaceError(rawValue: errSecParam)),
    ])
    func testEquatable_False(lhs: KeychainInterfaceError, rhs: KeychainInterfaceError) async throws {
        #expect(lhs != rhs)
        #expect(rhs != lhs)
    }

    @Test
    func testHashable_DeduplicatesEqualValues() async throws {
        let errors: Set<KeychainInterfaceError> = [
            .itemNotFound,
            KeychainInterfaceError(rawValue: errSecItemNotFound),
            KeychainInterfaceError(errSecItemNotFound),
            .duplicateItem,
        ]
        #expect(errors == [.itemNotFound, .duplicateItem])
    }

    @Test(arguments: [
        (KeychainInterfaceError.itemNotFound, "itemNotFound"),
        (KeychainInterfaceError.duplicateItem, "duplicateItem"),
        (KeychainInterfaceError(rawValue: errSecParam), "other"),
    ])
    func testCatchPattern(error: KeychainInterfaceError, expectedMatch: String) async throws {
        func match(_ error: KeychainInterfaceError) -> String {
            do throws(KeychainInterfaceError) {
                throw error
            } catch .itemNotFound {
                return "itemNotFound"
            } catch .duplicateItem {
                return "duplicateItem"
            } catch {
                return "other"
            }
        }

        #expect(match(error) == expectedMatch)
    }
}
