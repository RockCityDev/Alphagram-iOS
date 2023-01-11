


import PackageDescription

let package = Package(
    name: "TelegramApi",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "TelegramApi",
            targets: ["TelegramApi"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "TelegramApi",
            dependencies: [],
            path: "Sources"),
    ]
)
