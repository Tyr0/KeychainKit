@_exported import KeychainKit
@_exported import SwiftUI

extension KeychainKit.KeychainItem {

    /// A binding that reads and writes the preference through its store.
    ///
    /// Access this member on the backing wrapper, such as `_authenticationToken.projectedValue`.
    /// This extension does not synthesize a `$authenticationToken` accessor.
    public var projectedValue: Binding<Value> {
        return Binding(get: {
            return self.keychain[KeychainItem.self, account: self.account]
        }, set: { newValue in
            self.keychain[KeychainItem.self, account: self.account] = newValue
        })
    }

    /// A convenience alias for `projectedValue`.
    ///
    /// - Note: The Swift compiler [does not synthesize the `$` shorthand for `-projectedValue`
    /// when implemented in an external module](https://forums.swift.org/t/property-wrapper-projectedvalue-cannot-be-in-a-extension/70269).
    /// This property is available in order to clarify intent but is intended to be removed at a later date.
    @export(implementation) @inline(always) // forcibly inlined to maintain ABI stability when removed at a future date.
    public var binding: Binding<Value> {
        return self.projectedValue
    }
}
