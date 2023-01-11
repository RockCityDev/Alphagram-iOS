


import PackageDescription

let package = Package(
    name: "YuvConversion",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "YuvConversion",
            targets: ["YuvConversion"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "YuvConversion",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
