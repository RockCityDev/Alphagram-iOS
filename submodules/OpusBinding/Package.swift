


import PackageDescription

let package = Package(
    name: "OpusBinding",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "OpusBinding",
            targets: ["OpusBinding"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "OpusBinding",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders"),
                .headerSearchPath("PublicHeaders/OpusBinding"),
                .headerSearchPath("Sources"),
                .unsafeFlags(["-I../../../../core-xprojects/libopus/build/libopus/include"])
            ]),
    ]
)
