
internal import os.log

extension Logger {

    private enum Constants {

        static let subsystem = "com.calderone.KeychainKit"
    }

    internal static let keychain = Logger(subsystem: Constants.subsystem, category: "Keychain")

    internal static let keychainItem = Logger(subsystem: Constants.subsystem, category: "KeychainItem")

    internal static let systemKeychainInterface = Logger(subsystem: Constants.subsystem, category: "SystemKeychainInterface")
}
