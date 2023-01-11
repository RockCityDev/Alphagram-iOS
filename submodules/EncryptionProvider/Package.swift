


import PackageDescription

let package = Package(
    name: "EncryptionProvider",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "EncryptionProvider",
            targets: ["EncryptionProvider"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "EncryptionProvider",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders"),
            ]),
    ]
)
