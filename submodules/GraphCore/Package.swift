


import PackageDescription

let package = Package(
    name: "GraphCore",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "GraphCore",
            targets: ["GraphCore"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "GraphCore",
            dependencies: [],
            path: "Sources"),
    ]
)
