load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TBTransferAssetUI",
    module_name = "TBTransferAssetUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/AvatarNode:AvatarNode",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramUI/Components/AnimationCache:AnimationCache",
        "//submodules/TelegramUI/Components/MultiAnimationRenderer",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/QrCode:QrCode",
        "//submodules/QrCodeUI:QrCodeUI",
        "//submodules/DeviceAccess:DeviceAccess",
        
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SnapKit:SnapKit",
        "//Vendor/ProgressHUD:ProgressHUD",
        "//Vendor/SDWebImage:SDWebImage",
        "//Vendor/Web3swift:Web3swift",
        "//Vendor/Web3swiftCore:Web3swiftCore",
        
        "//TBModules/TBWeb3Core:TBWeb3Core",
        "//TBModules/TBNetwork:TBNetwork",
        "//TBThirdParty/WalletConnectSwift:WalletConnectSwift",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBDisplay:TBDisplay",
        "//TBModules/TBWalletCore:TBWalletCore",
        "//TBModules/TBLanguage:TBLanguage",
    ],
    visibility = [
        "//visibility:public",
    ],
)


