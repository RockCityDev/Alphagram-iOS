


import PackageDescription

let package = Package(
    name: "libphonenumber",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "libphonenumber",
            targets: ["libphonenumber"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "libphonenumber",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders")
            ]),
    ]
)
