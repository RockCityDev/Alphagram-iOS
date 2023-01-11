load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AGToolsCenterUI",
    module_name = "AGToolsCenterUI",
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
        "//submodules/ChatListUI:ChatListUI",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/TelegramUI/Components/AnimationCache:AnimationCache",
        "//submodules/TelegramUI/Components/MultiAnimationRenderer",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SnapKit:SnapKit",
        "//Vendor/ProgressHUD:ProgressHUD",
        "//Vendor/SDWebImage:SDWebImage",
        "//TBModules/TBWeb3Core:TBWeb3Core",
        "//TBModules/TBNetwork:TBNetwork",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBDisplay:TBDisplay",
        "//TBModules/TBTransferAssetUI:TBTransferAssetUI",
    ],
    visibility = [
        "//visibility:public",
    ],
)


