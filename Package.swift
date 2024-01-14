// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TextStorage",
    platforms: [.iOS("13.0")],
    products: [
        .library(
            name: "TextStorage",
            targets: ["TextStorage"]),
        /* .library(name: "fredbuf", targets: ["fredbuf"]) */
    ],
    targets: [
        .target(name: "TextStorage", dependencies: ["fredbuf"]),
        .target(name: "fredbuf"),
        .testTarget(
            name: "TextStorageTests",
            dependencies: ["TextStorage"]
        )
    ],
    cxxLanguageStandard: .cxx20
)
