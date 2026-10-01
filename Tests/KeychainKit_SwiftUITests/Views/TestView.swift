import KeychainKit
import KeychainKit_SwiftUI
import SwiftUI

struct TestView<Keychain>: View where Keychain: KeychainProtocol {

    // MARK: - Properties

    @KeychainItem<Keychain, TestKeychainItem>
    private var keychainItem: String?

    // MARK: - Lifecycle Functions

    init(keychain: Keychain) {
        self._keychainItem = KeychainItem(keychain: keychain, account: "TestAccount")
    }

    // MARK: - View Conformance

    var body: some View {
        if let binding = Binding(self._keychainItem.projectedValue) {
            SecureField("Test", text: binding)
        }
    }
}
