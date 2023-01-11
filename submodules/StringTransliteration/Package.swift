


import PackageDescription

let package = Package(
    name: "StringTransliteration",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "StringTransliteration",
            targets: ["StringTransliteration"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "StringTransliteration",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
