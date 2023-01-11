load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBWebUI",
    module_name = "TBWebUI",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/AvatarNode:AvatarNode",
        "//submodules/AccountContext:AccountContext",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/AppBundle:AppBundle",
        "//submodules/QrCodeUI:QrCodeUI",
        
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SnapKit:SnapKit",
        "//Vendor/ProgressHUD:ProgressHUD",
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/SDWebImage:SDWebImage",
        "//Vendor/MJRefresh:MJRefresh",
        
        "//TBModules/TBWalletCore:TBWalletCore",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBOpenSea:TBOpenSea",
        "//TBModules/TBBusinessNetwork:TBBusinessNetwork",
        "//TBModules/TBWeb3Core:TBWeb3Core",
        "//TBModules/TBDisplay:TBDisplay",
        "//TBModules/TBWalletUI:TBWalletUI",
        "//TBModules/TBQrCode:TBQrCode",
        "//TBModules/TBTransferAssetUI:TBTransferAssetUI",
        
        "//TBThirdParty/SwiftEntryKit:SwiftEntryKit",
        "//TBThirdParty/SegementSlide:SegementSlide",
        "//TBThirdParty/JXSegmentedView:JXSegmentedView",
    ],
    visibility = [
        "//visibility:public",
    ],
)
