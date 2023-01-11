


import PackageDescription

let package = Package(
    name: "ManagedFile",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "ManagedFile",
            targets: ["ManagedFile"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "SSignalKit", path: "../../submodules/telegram-ios/submodules/SSignalKit"),
    ],
    targets: [
        
        
        .target(
            name: "ManagedFile",
            dependencies: [
                .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil),
            ],
            path: ".",
            exclude: ["BUILD"]),
    ]
)
