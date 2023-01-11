


import PackageDescription

let package = Package(
    name: "MurMurHash32",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "MurMurHash32",
            targets: ["MurMurHash32"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "MurMurHash32",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
