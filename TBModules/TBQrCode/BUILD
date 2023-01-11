load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TBQrCode",
    module_name = "TBQrCode",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//submodules/AccountContext:AccountContext",
        "//submodules/Display:Display",
        "//submodules/Postbox:Postbox",
        "//submodules/TelegramCore:TelegramCore",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/QrCode:QrCode",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/ShareController:ShareController",
        "//submodules/UndoUI:UndoUI",
        
        "//TBModules/TBDisplay:TBDisplay",
        "//TBModules/TBLanguage:TBLanguage",
        
        "//Vendor/ProgressHUD:ProgressHUD",
    ],
    visibility = [
        "//visibility:public",
    ],
)
