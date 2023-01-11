


import PackageDescription

let package = Package(
    name: "sqlcipher",
    platforms: [.macOS(.v10_12)],
    products: [
        
        .library(
            name: "sqlcipher",
            targets: ["sqlcipher"]),
    ],
    dependencies: [
        
        // .package(url: , from: "1.0.0"),
    ],
    targets: [
        
        
        .target(
            name: "sqlcipher",
            dependencies: [],
            path: ".",
            exclude: ["BUILD"],
            publicHeadersPath: "PublicHeaders",
            cSettings: [
                .headerSearchPath("PublicHeaders"),
                .define("SQLITE_HAS_CODEC", to: "1"),
                .define("SQLCIPHER_CRYPTO_CC", to: "1"),
                .define("SQLITE_TEMP_STORE", to: "2"),
                .define("SQLITE_ENABLE_FTS5", to: "1"),
                .define("HAVE_USLEEP", to: "1"),
                .define("SQLITE_DEFAULT_MEMSTATUS", to: "0"),
                .define("SQLITE_OMIT_LOAD_EXTENSION", to: "1"),
                .define("SQLITE_OMIT_DECLTYPE", to: "1"),
                .define("SSQLITE_OMIT_PROGRESS_CALLBACK", to: "1"),
                .define("SQLITE_OMIT_DEPRECATED", to: "1"),
                .define("NDEBUG", to: "1"),
                .define("SQLITE_MAX_MMAP_SIZE", to: "0"),
            ]),
    ]
)
