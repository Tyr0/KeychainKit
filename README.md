# KeychainKit

A lightweight, observable, type-safe interface to the system keychain on Apple platforms. Describe each secret with a type, read and write it per account, observe changes with Swift `Observation`, and inject mock backends for testing.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS%20%7C%20watchOS-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)

## Overview

`Keychain` is an `Observable` facade over the Security framework's generic password items:

- **Typed items**: each secret is a type conforming to `KeychainItemProtocol`, declaring its service, value type, and default value.
- **Observable**: SwiftUI views and `withObservationTracking` clients are notified per item and account, so a change to one never invalidates readers of another.
- **Fresh reads**: every read queries the keychain, so changes made elsewhere are visible on the next read.
- **Typed throws**: every operation throws `KeychainError`, never an existential. The subscript is a non-throwing convenience that logs errors.
- **Protocolized**: the core interfaces sit behind protocols, so tests can inject an in-memory mock.

## Requirements

- Swift 6.3+
- iOS 18+ / macOS 15+ / tvOS 18+ / visionOS 2+ / watchOS 11+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Tyr0/KeychainKit.git", from: "0.2.0"),
]
```

Then add `KeychainKit` to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "KeychainKit", package: "KeychainKit"),
    ],
),
```

## Usage

Define a type for each secret. Its service identifies the item in the keychain, and its default value is returned when nothing is stored:

```swift
import KeychainKit

enum AuthTokenItem: KeychainItemProtocol {

    static let defaultValue: Optional<String> = nil

    static let service: String = "com.example.auth-token"
}
```

Read, write, and delete values per account:

```swift
let keychain = Keychain()

keychain[AuthTokenItem.self, account: userID] = "abc123"   // insert or update
keychain[AuthTokenItem.self, account: userID]              // "abc123"
keychain[AuthTokenItem.self, account: userID] = nil        // delete
```

Use a stable service unique to each item type. Types that share a service address the same stored items, and changing a service does not migrate existing items.

### Values

`Data`, `String` (stored as UTF-8), and `Optional` of either are supported out of the box. Conform your own types to `KeychainRepresentable` by converting them to and from `Data`:

```swift
extension Credential: KeychainRepresentable {

    init(keychainRepresentation: consuming Data) throws(DecodingError) {
        // Decode, throwing a DecodingError for invalid data.
    }

    var keychainRepresentation: Data? {
        get throws(EncodingError) {
            // Encode, or return nil to remove the item.
        }
    }
}
```

Writing a value whose representation is `nil`, such as `Optional.none`, removes the item. Subsequent reads return the item's `defaultValue`, which is not necessarily `nil`.

### Handling Errors

The subscript logs and discards errors: a failed read returns the default value, and a failed write leaves storage unchanged. When failure must be handled, most importantly to tell "absent" from "keychain unavailable", use the throwing methods:

```swift
do {
    let token = try keychain.value(forItem: AuthTokenItem.self, account: userID)
} catch .interactionNotAllowed {
    // The device is locked; the item still exists. Retry after unlock.
} catch .decodingError {
    // The stored data is not a valid value. The next write replaces it.
} catch {
    // Any other Security failure, e.g. `.securityError(let status)`.
}
```

Security failures are reported as `KeychainError.securityError(_:)` with the underlying status code. Common statuses, such as `.interactionNotAllowed` and `.missingEntitlement`, can be caught directly by name.

Errors are never cached: after a failed read, the next access queries the keychain again.

### Observation

`Keychain` participates in Swift `Observation`, so SwiftUI views track exactly the items and accounts they read. Derive non-sensitive state, such as whether a secret is present, rather than rendering the secret itself:

```swift
struct AccountView: View {

    let keychain: Keychain<SystemKeychainInterface>

    let userID: String

    private var isSignedIn: Bool {
        return self.keychain[AuthTokenItem.self, account: self.userID] != nil
    }

    var body: some View {
        if self.isSignedIn {
            SignOutButton()
        } else {
            SignInButton()
        }
    }
}
```

Writes and removals invalidate readers of the same service and account across every system-backed `Keychain` instance, whether created with `Keychain.default`, `Keychain()`, or `Keychain(accessGroup:)`.
Notifications are not scoped by access group, so a write in one group also invalidates readers in another.
A `Keychain` created in generic code (`Keychain<Interface>(interface:)`) and keychains backed by other interfaces notify only their own readers.
Other processes, such as app extensions, do not trigger these notifications; a subsequent read retrieves their changes.
Notifications also occur for equal-value writes, absent-item removals, and failed operations, so a notification is not proof that storage changed.

### Access Groups

By default, items are inserted into the app's first keychain access group, while reads, updates, and removals match items in every access group the app belongs to.
To share items between an app and its extensions, scope the keychain to a shared group:

```swift
let keychain = Keychain(accessGroup: "TEAMID.com.example.shared")
```

### Testing

Depend on `KeychainProtocol` rather than a concrete `Keychain`, and inject a `Keychain` backed by an in-memory `KeychainInterfaceProtocol` conformance.
Storage forwarding and observation are exercised for real while the system keychain is never touched:

```swift
let keychain = Keychain(interface: MockKeychainInterface())
```

## Behavior

- **Storage**: items are generic passwords in the data-protection keychain. By default they use `kSecAttrAccessibleWhenUnlocked`: readable only while the device is unlocked, never synced to iCloud, and never restored to another device from a backup. Protection is applied when an item is inserted; updating an existing item replaces only its data.
- **Freshness**: values and missing items are never cached. Each read performs a synchronous keychain query, so repeated reads incur storage latency.
- **Concurrency**: reads, writes, and removals through one instance share a lock, including operations on different items. Other writers and direct interface calls do not use that lock. Updating an absent item requires an update followed by an insertion; if another writer inserts first, the update is retried once. These operations are not an atomic transaction across writers.
- **Operation cost**: reads and removals each issue one storage call. Updating an existing item issues one call; inserting an absent item issues two, or three when an insertion collision requires retrying the update. Equal-value writes still reach storage and notify observers.

> [!NOTE]
> On macOS the data-protection keychain requires a signed app with an
> application identifier. Unsigned processes, including Swift package test
> runners, fail with `KeychainError.missingEntitlement`.

## License

Released under the MIT License. See [LICENSE.md](LICENSE.md).
