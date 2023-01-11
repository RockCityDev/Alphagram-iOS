


import PackageDescription

let package = Package(
    name: "SSignalKit",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "SwiftSignalKit",
            targets: ["SwiftSignalKit"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "SwiftSignalKit",
            dependencies: [],
            path: "SwiftSignalKit/Source"),
    ]
)
