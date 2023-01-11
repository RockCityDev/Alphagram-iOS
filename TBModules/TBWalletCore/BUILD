load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBWalletCore",
    module_name = "TBWalletCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        
        "//TBModules/TBBusinessNetwork:TBBusinessNetwork",
        "//TBModules/TBStorage:TBStorage",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBOpenSea:TBOpenSea",
        "//TBModules/TBTrack:TBTrack",
        
        "//Vendor/Web3swift:Web3swift",
        "//Vendor/Web3swiftCore:Web3swiftCore",
        "//Vendor/ProgressHUD:ProgressHUD",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/RxSwift:RxSwift",
        
        "//TBThirdParty/WalletConnectSwift:WalletConnectSwift",
        "//TBThirdParty/ParticleFrameworks:ParticleNetworkBase",
        "//TBThirdParty/ParticleFrameworks:ParticleAuthService",
        "//TBThirdParty/ParticleFrameworks:ParticleWalletAPI",
    ],
    visibility = [
        "//visibility:public",
    ],
)
