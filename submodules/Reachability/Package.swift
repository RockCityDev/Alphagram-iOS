


import PackageDescription

let package = Package(
    name: "Reachability",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "Reachability",
            targets: ["Reachability"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
        .package(name: "LegacyReachability", path: "LegacyReachability"),
        .package(name: "SSignalKit", path: "../SSignalKit"),
    ],
    targets: [
        
        
        .target(
            name: "Reachability",
            dependencies: [.product(name: "LegacyReachability", package: "LegacyReachability", condition: nil),
                           .product(name: "SwiftSignalKit", package: "SSignalKit", condition: nil)],
            path: "Sources"),
    ]
)
