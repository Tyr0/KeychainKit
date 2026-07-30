
import Foundation

public enum KeychainError: Equatable, Error, Sendable {

    case duplicateItem

    case interactionNotAllowed

    case itemNotFound

    case unknownError(OSStatus)
}
