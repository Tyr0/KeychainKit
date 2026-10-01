import KeychainKit

struct TestInvalidKeychainRepresentable {

    // MARK: - Lifecycle Functions

    init() {

    }
}

extension TestInvalidKeychainRepresentable: KeychainRepresentable {

    init(keychainRepresentation: consuming KeychainRepresentation) throws(DecodingError) {
        throw DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: [],
            debugDescription: "Explicit decoding failure of \(Self.self).",
        ))
    }

    var keychainRepresentation: KeychainRepresentation? {
        get throws(EncodingError) {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: [],
                debugDescription: "Explicit encoding failure of \(Self.self).",
            ))
        }
    }
}
