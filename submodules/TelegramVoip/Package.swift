


import PackageDescription

let package = Package(
    name: "TelegramVoip",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "TelegramVoip",
            targets: ["TelegramVoip"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "TgVoipWebrtc", path: "../../../tgcalls"),
        .package(name: "SSignalKit", path: "../SSignalKit"),
        .package(name: "TelegramCore", path: "../TelegramCore")

    ],
    targets: [
        
        
        .target(
            name: "TelegramVoip",
            dependencies: [
                .product(name: "TgVoipWebrtc", package: "TgVoipWebrtc", condition: nil),
                .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
                .product(name: "TelegramCore", package: "TelegramCore", condition: nil),
            ],
            path: "Sources",
            exclude: [
                "IpcGroupCallContext.swift",
                "OngoingCallContext.swift",
            ],
            cxxSettings: [
                .define("WEBRTC_MAC", to: "1", nil),
            ]),
    ]
)
