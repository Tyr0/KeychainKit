import Observation

/// A ``KeychainInterfaceProtocol`` that supplies the observation registrar shared by every
/// ``Keychain`` backed by the same storage.
///
/// Conformances return the same registrar for every value that addresses the same storage,
/// so updates and removals through one ``Keychain`` notify readers of another.
internal protocol ObservableKeychainInterfaceProtocol: KeychainInterfaceProtocol {

    /// The registrar shared by every ``Keychain`` backed by this storage.
    var observationRegistrar: ObservationRegistrar { get }
}
