// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KeychainKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2),
    ],
    products: [
        .library(
            name: "KeychainKit",
            targets: [
                "KeychainKit",
            ],
        ),
        .library(
            name: "KeychainKit_SwiftUI",
            targets: [
                "KeychainKit_SwiftUI",
            ],
        ),
    ],
    targets: [
        .target(
            name: "KeychainKit",
        ),
        .target(
            name: "KeychainKit_SwiftUI",
            dependencies: [
                "KeychainKit",
            ],
        ),
        .testTarget(
            name: "KeychainKitTests",
            dependencies: ["KeychainKit"]
        ),
        .testTarget(
            name: "KeychainKit_SwiftUITests",
            dependencies: [
                "KeychainKit",
                "KeychainKit_SwiftUI",
            ],
        ),
    ],
    swiftLanguageModes: [.v6]
)
