load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBWeb3Core",
    module_name = "TBWeb3Core",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//TBModules/TBBusinessNetwork:TBBusinessNetwork",
        "//TBModules/TBStorage:TBStorage",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Vendor/HandyJSON:HandyJSON",
        "//submodules/AccountContext:AccountContext",
        "//TBModules/TBWalletCore:TBWalletCore",
        "//TBModules/TBAccount:TBAccount",
        "//TBModules/TBLanguage:TBLanguage",
        "//submodules/AppBundle:AppBundle",
    ],
    visibility = [
        "//visibility:public",
    ],
)
