import Foundation
import Security
import Testing

@testable import KeychainKit

@Suite
struct KeychainErrorTests {

    private enum Constants {

        static let decodingError = KeychainError.decodingError(DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: [],
            debugDescription: "Explicit decoding failure."
        )))

        static let encodingError = KeychainError.encodingError(EncodingError.invalidValue("Secret", EncodingError.Context(
            codingPath: [],
            debugDescription: "Explicit encoding failure."
        )))
    }

    @Test(arguments: [
        (KeychainError.interactionNotAllowed, KeychainInterfaceError.interactionNotAllowed),
        (KeychainError.missingEntitlement, KeychainInterfaceError.missingEntitlement),
    ])
    func testStaticMembers_WrapSecurityError(error: KeychainError, expectedUnderlyingError: KeychainInterfaceError) async throws {
        guard case .securityError(let underlyingError) = error else {
            Issue.record("Expected .securityError, received \(error)")
            return
        }

        #expect(underlyingError == expectedUnderlyingError)
    }

    @Test(arguments: [
        (Constants.decodingError, ".decodingError"),
        (Constants.encodingError, ".encodingError"),
        (KeychainError.securityError(.itemNotFound), ".securityError(KeychainInterfaceError(-25300))"),
        (KeychainError.interactionNotAllowed, ".securityError(KeychainInterfaceError(-25308))"),
    ])
    func testDescription(error: KeychainError, expectedDescription: String) async throws {
        #expect(error.description == expectedDescription)
    }

    @Test(arguments: [
        (KeychainError.interactionNotAllowed, KeychainError.interactionNotAllowed),
        (KeychainError.interactionNotAllowed, KeychainError.securityError(.interactionNotAllowed)),
        (KeychainError.missingEntitlement, KeychainError.securityError(KeychainInterfaceError(rawValue: errSecMissingEntitlement))),
        (KeychainError.securityError(.itemNotFound), KeychainError.securityError(.itemNotFound)),
    ])
    func testPatternMatch_True(pattern: KeychainError, value: KeychainError) async throws {
        #expect(pattern ~= value)
        #expect(value ~= pattern)
    }

    @Test(arguments: [
        (KeychainError.interactionNotAllowed, KeychainError.missingEntitlement),
        (KeychainError.securityError(.itemNotFound), KeychainError.securityError(.duplicateItem)),
        (KeychainError.interactionNotAllowed, Constants.decodingError),
        (KeychainError.interactionNotAllowed, Constants.encodingError),
        (Constants.decodingError, Constants.decodingError),
        (Constants.encodingError, Constants.encodingError),
        (Constants.decodingError, Constants.encodingError),
    ])
    func testPatternMatch_False(pattern: KeychainError, value: KeychainError) async throws {
        #expect(!(pattern ~= value))
        #expect(!(value ~= pattern))
    }

    @Test(arguments: [
        (KeychainError.interactionNotAllowed, "interactionNotAllowed"),
        (KeychainError.missingEntitlement, "missingEntitlement"),
        (KeychainError.securityError(.itemNotFound), "securityError(-25300)"),
        (Constants.decodingError, "decodingError"),
        (Constants.encodingError, "encodingError"),
    ])
    func testCatchPattern(error: KeychainError, expectedMatch: String) async throws {
        func match(_ error: KeychainError) -> String {
            do throws(KeychainError) {
                throw error
            } catch .interactionNotAllowed {
                return "interactionNotAllowed"
            } catch .missingEntitlement {
                return "missingEntitlement"
            } catch .decodingError {
                return "decodingError"
            } catch .encodingError {
                return "encodingError"
            } catch {
                // Typed `catch` clauses are never treated as exhaustive, so the final clause must be unconditional.
                guard case .securityError(let underlyingError) = error else {
                    return "unreachable"
                }

                return "securityError(\(underlyingError.rawValue))"
            }
        }

        #expect(match(error) == expectedMatch)
    }

    @Test
    func testDecodingError_PreservesUnderlyingError() async throws {
        guard case .decodingError(.dataCorrupted(let context)) = Constants.decodingError else {
            Issue.record("Expected .decodingError(.dataCorrupted), received \(Constants.decodingError)")
            return
        }

        #expect(context.debugDescription == "Explicit decoding failure.")
    }

    @Test
    func testEncodingError_PreservesUnderlyingError() async throws {
        guard case .encodingError(.invalidValue(let value, let context)) = Constants.encodingError else {
            Issue.record("Expected .encodingError(.invalidValue), received \(Constants.encodingError)")
            return
        }

        #expect(value as? String == "Secret")
        #expect(context.debugDescription == "Explicit encoding failure.")
    }
}
