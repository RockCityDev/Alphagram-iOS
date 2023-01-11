


import PackageDescription


let package = Package(
    name: "OpenSSLEncryption",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "OpenSSLEncryption",
            targets: ["OpenSSLEncryption"]),
    ],
    targets: [
        .target(
            name: "OpenSSLEncryption",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders"),
                .unsafeFlags([
                    "-I../../../../core-xprojects/openssl/build/openssl/include",
                    "-I../EncryptionProvider/PublicHeaders"
                ])
            ]),
    ]
)
