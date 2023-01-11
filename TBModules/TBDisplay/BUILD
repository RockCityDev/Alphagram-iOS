load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

# TBDisplay
swift_library(
    name = "TBDisplay",
    module_name = "TBDisplay",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
            "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
            "//submodules/AsyncDisplayKit:AsyncDisplayKit",
            "//submodules/Display:Display",
            "//submodules/TelegramCore:TelegramCore",
            "//submodules/TelegramPresentationData:TelegramPresentationData",
            "//submodules/PeerPresenceStatusManager:PeerPresenceStatusManager",
            "//submodules/TelegramStringFormatting:TelegramStringFormatting",
            "//submodules/AvatarNode:AvatarNode",
            "//submodules/ActivityIndicator:ActivityIndicator",
            "//submodules/ItemListUI:ItemListUI",
            "//submodules/AppBundle:AppBundle",
            "//submodules/PresentationDataUtils:PresentationDataUtils",
            "//submodules/PhoneNumberFormat:PhoneNumberFormat",
            "//submodules/AccountContext:AccountContext",
            "//Vendor/SnapKit:SnapKit",
            "//Vendor/SDWebImage:SDWebImage",
            "//TBModules/TBAccount:TBAccount",
            "//TBModules/TBWeb3Core:TBWeb3Core",
            "//TBThirdParty/SwiftEntryKit:SwiftEntryKit",
                    
    ],
    visibility = [
        "//visibility:public",
    ],
)
