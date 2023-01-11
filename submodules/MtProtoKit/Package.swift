


import PackageDescription

let package = Package(
    name: "MtProtoKit",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "MtProtoKit",
            targets: ["MtProtoKit"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "EncryptionProvider", path: "../EncryptionProvider")
    ],
    targets: [
        
        
        .target(
            name: "MtProtoKit",
            dependencies: [.product(name: "EncryptionProvider", package: "EncryptionProvider", condition: nil)],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders"),
            ]),
    ]
)
