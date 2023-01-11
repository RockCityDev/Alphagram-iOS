


import PackageDescription

let package = Package(
    name: "Crc32",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "Crc32",
            targets: ["Crc32"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "Crc32",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
