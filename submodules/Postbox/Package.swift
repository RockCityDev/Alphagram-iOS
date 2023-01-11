


import PackageDescription

let package = Package(
    name: "Postbox",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "Postbox",
            targets: ["Postbox"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "MurMurHash32", path: "../MurMurHash32"),
        .package(name: "Crc32", path: "../Crc32"),
        .package(name: "sqlcipher", path: "../sqlcipher"),
        .package(name: "StringTransliteration", path: "../StringTransliteration"),
        .package(name: "ManagedFile", path: "../ManagedFile"),
        .package(name: "RangeSet", path: "../Utils/RangeSet"),
        .package(name: "SSignalKit", path: "../SSignalKit"),
    ],
    targets: [
        
        
        .target(
            name: "Postbox",
            dependencies: [.product(name: "MurMurHash32", package: "MurMurHash32", condition: nil),
                            .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
                           .product(name: "ManagedFile", package: "ManagedFile", condition: nil),
                           .product(name: "RangeSet", package: "RangeSet", condition: nil),
                           .product(name: "sqlcipher", package: "sqlcipher", condition: nil),
                           .product(name: "StringTransliteration", package: "StringTransliteration", condition: nil),
                           .product(name: "Crc32", package: "Crc32", condition: nil)],
            path: "Sources"),
    ]
)
