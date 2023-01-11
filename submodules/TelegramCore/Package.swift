


import PackageDescription

let package = Package(
    name: "TelegramCore",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "TelegramCore",
            targets: ["TelegramCore"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "Postbox", path: "../Postbox"),
        .package(name: "SSignalKit", path: "../SSignalKit"),
        .package(name: "MtProtoKit", path: "../MtProtoKit"),
        .package(name: "TelegramApi", path: "../TelegramApi"),
        .package(name: "CryptoUtils", path: "../CryptoUtils"),
        .package(name: "NetworkLogging", path: "../NetworkLogging"),
        .package(name: "Reachability", path: "../Reachability"),
        .package(name: "EncryptionProvider", path: "../EncryptionProvider"),
    ],
    targets: [
        
        
        .target(
            name: "TelegramCore",
            dependencies: [.product(name: "Postbox", package: "Postbox", condition: nil),
                            .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
                            .product(name: "MtProtoKit", package: "MtProtoKit", condition: nil),
                           .product(name: "TelegramApi", package: "TelegramApi", condition: nil),
                           .product(name: "CryptoUtils", package: "CryptoUtils", condition: nil),
                           .product(name: "NetworkLogging", package: "NetworkLogging", condition: nil),
                           .product(name: "Reachability", package: "Reachability", condition: nil),
                           .product(name: "EncryptionProvider", package: "EncryptionProvider", condition: nil)],
            path: "Sources"),
    ]
)
