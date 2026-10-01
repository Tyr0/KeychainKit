import Foundation

/// A value that can be stored as the data of a keychain item.
///
/// KeychainKit provides conformances for `Data`, `String` (as UTF-8), and `Optional`
/// wrapping any conforming type. Conform your own types by converting them to and
/// from `Data`:
///
/// ```swift
/// extension Credential: KeychainRepresentable {
///
///     init(keychainRepresentation: consuming Data) throws(DecodingError) {
///         do {
///             self = try JSONDecoder().decode(Credential.self, from: keychainRepresentation)
///         } catch let error as DecodingError {
///             throw error
///         } catch {
///             throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid credential data.", underlyingError: error))
///         }
///     }
///
///     var keychainRepresentation: Data? {
///         get throws(EncodingError) {
///             do {
///                 return try JSONEncoder().encode(self)
///             } catch let error as EncodingError {
///                 throw error
///             } catch {
///                 throw EncodingError.invalidValue(self, .init(codingPath: [], debugDescription: "Invalid credential.", underlyingError: error))
///             }
///         }
///     }
/// }
/// ```
public protocol KeychainRepresentable: Equatable, Sendable {

    /// The stored form of a value.
    typealias KeychainRepresentation = Data

    /// Creates a value from its stored form.
    ///
    /// - Parameters:
    ///   - keychainRepresentation: The data stored in the keychain item.
    /// - Throws: A `DecodingError` when the data does not represent a valid value.
    ///   To report a failure of another type, wrap it as the `underlyingError` of
    ///   `DecodingError.dataCorrupted(_:)`.
    init(keychainRepresentation: consuming KeychainRepresentation) throws(DecodingError)

    /// The data to store for this value, or `nil` to remove the item.
    ///
    /// Returning `nil` makes ``KeychainProtocol/updateValue(_:forItem:account:)`` remove
    /// the item rather than store an empty value.
    ///
    /// - Throws: An `EncodingError` when the value cannot be converted to data.
    ///   `EncodingError.invalidValue(_:_:)` carries the value itself, so take care when
    ///   logging or reporting the error.
    var keychainRepresentation: KeychainRepresentation? { get throws(EncodingError) }
}

extension Data: KeychainRepresentable {

    /// Creates data from its stored form, unchanged.
    public init(keychainRepresentation: consuming KeychainRepresentation) throws(DecodingError) {
        self = keychainRepresentation
    }

    /// The data itself. An empty value is stored as an empty item, not removed.
    public var keychainRepresentation: KeychainRepresentation? {
        return self
    }
}

extension Optional: KeychainRepresentable where Wrapped: KeychainRepresentable {

    /// Creates a wrapped value from its stored form.
    ///
    /// A stored item always decodes to `.some`; an absent item is reported through
    /// ``KeychainItemProtocol/defaultValue`` instead.
    ///
    /// - Throws: The `DecodingError` thrown by the wrapped type.
    public init(keychainRepresentation: consuming KeychainRepresentation) throws(DecodingError) {
        self = .some(try Wrapped(keychainRepresentation: keychainRepresentation))
    }

    /// The wrapped value's stored form, or `nil` to remove the item when the value is `nil`.
    ///
    /// Nested optionals collapse: `.some(.none)` also removes the item.
    public var keychainRepresentation: KeychainRepresentation? {
        get throws(EncodingError) {
            switch self {
            case .none:
                return nil
            case .some(let representable):
                return try representable.keychainRepresentation
            }
        }
    }
}

extension String: KeychainRepresentable {

    /// Creates a string from UTF-8 data.
    ///
    /// - Throws: `DecodingError.dataCorrupted(_:)` when the data is not valid UTF-8.
    public init(keychainRepresentation: consuming KeychainRepresentation) throws(DecodingError) {
        guard let string = String(validating: keychainRepresentation, as: UTF8.self) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "The stored data is not valid UTF-8."))
        }

        self = string
    }

    /// The string's UTF-8 encoding. An empty string is stored as an empty item, not removed.
    public var keychainRepresentation: KeychainRepresentation? {
        return Data(self.utf8)
    }
}
