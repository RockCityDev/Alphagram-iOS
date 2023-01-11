


import PackageDescription

let package = Package(
    name: "CryptoUtils",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "CryptoUtils",
            targets: ["CryptoUtils"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "CryptoUtils",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
