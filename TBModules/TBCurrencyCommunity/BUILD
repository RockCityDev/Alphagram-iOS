load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBCurrencyCommunity",
    module_name = "TBCurrencyCommunity",
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
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AccountContext:AccountContext",
        "//submodules/AppBundle:AppBundle",
        "//submodules/SolidRoundedButtonNode:SolidRoundedButtonNode",
        "//submodules/AnimatedStickerNode:AnimatedStickerNode",
        "//submodules/TelegramAnimatedStickerNode:TelegramAnimatedStickerNode",
        "//submodules/PresentationDataUtils:PresentationDataUtils",
        "//submodules/GlassButtonNode:GlassButtonNode",
        "//submodules/TextFormat:TextFormat",
        "//submodules/Markdown:Markdown",
        "//submodules/UndoUI:UndoUI",
        "//submodules/LegacyUI:LegacyUI",
        "//submodules/LegacyComponents:LegacyComponents",
        "//submodules/LegacyMediaPickerUI:LegacyMediaPickerUI",
        "//submodules/ImageContentAnalysis:ImageContentAnalysis",
        "//TBModules/TBBusinessNetwork:TBBusinessNetwork",
        "//TBModules/TBStorage:TBStorage",
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/SnapKit:SnapKit",
        "//Vendor/ProgressHUD:ProgressHUD",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/SDWebImage:SDWebImage",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBWalletCore:TBWalletCore",
        "//Vendor/MJRefresh:MJRefresh",
        "//TBThirdParty/SegementSlide:SegementSlide",
        "//TBModules/TBSegementSlide:TBSegementSlide",
        "//TBThirdParty/WalletConnectSwift:WalletConnectSwift",
        "//TBModules/TBWeb3Core:TBWeb3Core",
        "//TBModules/TBDisplay:TBDisplay",
        "//TBThirdParty/JXSegmentedView:JXSegmentedView",
        "//TBModules/TBTrack:TBTrack",
        "//TBModules/TBLanguage:TBLanguage",
    ],
    visibility = [
        "//visibility:public",
    ],
)
