


import PackageDescription

let package = Package(
    name: "LegacyReachability",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "LegacyReachability",
            targets: ["LegacyReachability"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "LegacyReachability",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
