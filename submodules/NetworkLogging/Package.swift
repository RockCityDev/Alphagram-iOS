


import PackageDescription

let package = Package(
    name: "NetworkLogging",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "NetworkLogging",
            targets: ["NetworkLogging"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "MtProtoKit", path: "../MtProtoKit")
    ],
    targets: [
        
        
        .target(
            name: "NetworkLogging",
            dependencies: [.product(name: "MtProtoKit", package: "MtProtoKit", condition: nil)],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
