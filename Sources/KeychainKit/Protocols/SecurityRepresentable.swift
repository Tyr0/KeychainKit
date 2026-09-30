
import Foundation

internal import CoreFoundation

internal protocol SecurityRepresentable {

    associatedtype SecurityRepresentation: CFTypeRef

    var securityValue: SecurityRepresentation { get }
}

extension Bool: SecurityRepresentable {

    var securityValue: CFBoolean {
        switch self {
        case true:
            return kCFBooleanTrue
        case false:
            return kCFBooleanFalse
        }
    }
}

extension Data: SecurityRepresentable {

    var securityValue: CFData {
        return self as CFData
    }
}

extension String: SecurityRepresentable {

    var securityValue: CFString {
        return self as CFString
    }
}
