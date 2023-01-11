load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_framework_import")


apple_static_framework_import(
    name = "ParticleNetworkBase",
    framework_imports = glob(["Frameworks/ParticleNetworkBase.framework/**"]),
    deps = [
        "//Vendor/CryptoSwift:CryptoSwift",
    ],
    visibility = ["//visibility:public"],
)

apple_static_framework_import(
    name = "ParticleAuthService",
    framework_imports = glob(["Frameworks/ParticleAuthService.framework/**"]),
    deps = [
        "//Vendor/CryptoSwift:CryptoSwift",
        "//Vendor/RxSwift:RxSwift",
        "//Vendor/RxAlamofire:RxAlamofire",
        "//Vendor/RxCocoa:RxCocoa",
        "//Vendor/RxRelay:RxRelay",
        "//Vendor/SwiftyJSON:SwiftyJSON",
        "//Vendor/GRDB:GRDB",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SwiftyUserDefaults:SwiftyUserDefaults",
        "//TBThirdParty/ParticleFrameworks:ParticleNetworkBase"
    ],
    visibility = ["//visibility:public"],
)

apple_static_framework_import(
    name = "ParticleWalletAPI",
    framework_imports = glob(["Frameworks/ParticleWalletAPI.framework/**"]),
    deps = [
        "//Vendor/CryptoSwift:CryptoSwift",
        "//Vendor/RxSwift:RxSwift",
        "//Vendor/RxAlamofire:RxAlamofire",
        "//Vendor/RxCocoa:RxCocoa",
        "//Vendor/RxRelay:RxRelay",
        "//Vendor/SwiftyJSON:SwiftyJSON",
        "//Vendor/GRDB:GRDB",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SwiftyUserDefaults:SwiftyUserDefaults",
        "//TBThirdParty/ParticleFrameworks:ParticleNetworkBase",
    ],
    visibility = ["//visibility:public"],
)

#apple_static_framework_import(
#    name = "ParticleNetworkBase",
#    framework_imports = select({
#        "@//config:is_arm": glob(["XCFrameworks/ParticleNetworkBase.xcframework/ios-arm64/ParticleNetworkBase.framework/**"]),
#        "@//conditions:default": glob(["XCFrameworks/ParticleNetworkBase.xcframework/ios-arm64_x86_64-simulator/ParticleNetworkBase.framework/**"]),
#    }),
#    deps = [
#        "//Vendor/CryptoSwift:CryptoSwift",
#    ],
#    visibility = ["//visibility:public"],
#)
