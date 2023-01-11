


import PackageDescription

let package = Package(
    name: "RangeSet",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "RangeSet",
            targets: ["RangeSet"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "RangeSet",
            dependencies: [],
            path: "Sources")
    ]
)
