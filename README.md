# KeychainKit

A lightweight, observable interface to the system keychain on Apple platforms.
Store and retrieve secrets with dictionary-like subscripts, observe per-key
changes with Swift `Observation`, and inject mock backends for testing.

![License](https://img.shields.io/badge/License-MIT-green.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20visionOS%20%7C%20watchOS-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.3-orange.svg)

## Overview

`Keychain` is an `Observable` facade over the Security framework's generic
password items:

- **Dictionary-like** — read, write, and delete via subscripts; `updateValue`
  and `removeValue` return the previous value, mirroring `Dictionary`.
- **Observable** — SwiftUI views and `withObservationTracking` clients are
  notified per key, so a change to one key never invalidates readers of
  another. Writes that don't change the stored value notify no one.
- **Cached** — values are cached in memory after first access; repeated reads
  don't touch the keychain.
- **Typed throws** — every operation throws `KeychainError`, never an
  existential; subscripts are non-throwing conveniences that discard errors.
- **Protocolized** — the Security framework sits behind
  `KeychainInterfaceProtocol`, so tests can inject an in-memory mock and
  exercise real cache and observation behavior.

## Requirements

- Swift 6.3+
- iOS 18+ / macOS 15+ / tvOS 18+ / visionOS 2+ / watchOS 11+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Tyr0/KeychainKit.git", from: "1.0.0"),
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

Read, write, and delete values with subscripts:

```swift
import KeychainKit

let keychain = Keychain()

keychain["authToken"] = "abc123"   // insert or update
keychain["authToken"]              // "abc123"
keychain["authToken"] = nil        // delete

keychain["theme", default: "light"]   // "light" when absent
```

A string key stores a generic password item whose account is the string and
whose service is the app's bundle identifier. Use `KeychainAttributes` to
address a different service explicitly:

```swift
let key = KeychainAttributes(account: "authToken", service: "com.example.shared")
keychain[key] = "abc123"
```

Because `KeychainAttributes` is `ExpressibleByStringLiteral`, it can back a
raw-value enum for typed keys:

```swift
enum SecretKey: KeychainAttributes {
    case authToken = "auth-token"
    case refreshToken = "refresh-token"
}

keychain[SecretKey.authToken] = "abc123"
```

### Handling Errors

Subscripts discard errors: a failed read returns `nil` (or the default), and a
failed write is silently dropped. When failure must be observable — most
importantly to distinguish "absent" from "keychain unavailable" — use the
throwing methods:

```swift
do {
    let token = try keychain.value(forKey: "authToken")
} catch KeychainError.interactionNotAllowed {
    // device is locked; the item still exists — retry after unlock
} catch {
    // ...
}
```

Errors are never cached: after a failed read, the next access queries the
keychain again.

### Observation

`Keychain` participates in Swift `Observation`, so SwiftUI views track exactly
the keys they read. Derive non-sensitive state — such as whether a secret is
present — rather than rendering the secret itself:

```swift
struct AccountView: View {

    let keychain: Keychain<SystemKeychainInterface>

    private var isSignedIn: Bool {
        return keychain["authToken"] != nil
    }

    var body: some View {
        if isSignedIn {
            SignOutButton()
        } else {
            SignInButton()
        }
    }
}
```

The view re-renders when `authToken` changes — signing in or out updates it
automatically — while the token's value never reaches the view hierarchy.

### Testing

Conform a mock to `KeychainInterfaceProtocol` and inject it — the cache and
observation layer is exercised for real while the system keychain is never
touched:

```swift
let keychain = Keychain(interface: MockKeychainInterface())
```

## Behavior

- **Storage** — items are stored as generic passwords in the data-protection
  keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`: readable only
  while the device is unlocked, never synced to iCloud, and never migrated to
  a new device.
- **Caching** — the in-memory cache assumes this instance is the only writer
  for its keys. Writes from other processes or components are not observed
  once a key is cached; deletes are always issued to the keychain regardless
  of cache state.
- **Values** — values are UTF-8 strings. A pre-existing item whose data is not
  valid UTF-8 reads as absent and is replaced by the next write.

> [!NOTE]
> On macOS the data-protection keychain requires a signed app with an
> application identifier. Unsigned processes — including Swift package test
> runners — fail with `KeychainError.missingEntitlement`.

## API

```swift
public final class Keychain<Interface>: KeychainProtocol, Sendable where Interface: KeychainInterfaceProtocol {

    /// Creates a keychain backed by the system keychain.
    public convenience init() where Interface == SystemKeychainInterface

    /// Creates a keychain backed by the given interface.
    public init(interface: Interface)

    /// Reads the value for a key; a failed read returns `nil`.
    /// Writes a value for a key, or removes it when `nil`; a failed write is discarded.
    public subscript(key: KeychainAttributes) -> String? { get set }

    /// Reads the value for a key, returning a default when absent or unreadable.
    public subscript(key: KeychainAttributes, default defaultValue: @autoclosure () -> String) -> String { get }

    /// Returns the value for a key, or `nil` when absent.
    public func value(forKey key: KeychainAttributes) throws(KeychainError) -> String?

    /// Inserts or updates the value for a key, returning the previous value.
    @discardableResult
    public func updateValue(_ value: String, forKey key: KeychainAttributes) throws(KeychainError) -> String?

    /// Removes the value for a key, returning the removed value.
    @discardableResult
    public func removeValue(forKey key: KeychainAttributes) throws(KeychainError) -> String?
}
```

```swift
public struct KeychainAttributes: Equatable, ExpressibleByStringLiteral, Hashable, Sendable {

    /// The bundle identifier, or the process name when unavailable.
    public static let defaultService: String

    /// The account name of the item.
    public let account: String

    /// The service the item belongs to.
    public let service: String

    /// Creates attributes for the given account and service.
    public init(account: String, service: String = KeychainAttributes.defaultService)
}
```

```swift
public enum KeychainError: Equatable, Error, Sendable {

    /// An item already exists for the key.
    case duplicateItem

    /// The keychain is unavailable, typically because the device is locked.
    case interactionNotAllowed

    /// No item exists for the key.
    case itemNotFound

    /// The process lacks the entitlements required to access the keychain.
    case missingEntitlement

    /// Any other Security framework failure.
    case unknownError(OSStatus)
}
```

## License

Released under the MIT License. See [LICENSE.md](LICENSE.md).
