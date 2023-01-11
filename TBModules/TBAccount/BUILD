load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBAccount",
    module_name = "TBAccount",
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
    ],
    visibility = [
        "//visibility:public",
    ],
)
