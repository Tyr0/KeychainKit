
import SwiftUI
import Testing

@testable import KeychainKit
@testable import KeychainKit_SwiftUI

@MainActor @Suite
struct PreferenceTests {

    @Test
    func testBindingCompilation() async throws {
        let keychain = Keychain()

        let view = TestView(keychain: keychain)

        _ = view.body
    }
}
