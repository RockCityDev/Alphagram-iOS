


import PackageDescription

let package = Package(
    name: "FFMpegBinding",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "FFMpegBinding",
            targets: ["FFMpegBinding"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "FFMpegBinding",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "Public",
            cSettings: [
                .headerSearchPath("Public"),
                .unsafeFlags(["-I../../../../core-xprojects/ffmpeg/build/ffmpeg/include"])
            ]),
    ]
)
