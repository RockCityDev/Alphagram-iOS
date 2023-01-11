load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB  json, Tg
    name = "TBBusinessNetwork",
    module_name = "TBBusinessNetwork",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//TBModules/TBNetwork:TBNetwork",
        "//TBModules/TBStorage:TBStorage",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/HandyJSON:HandyJSON",
    ],
    visibility = [
        "//visibility:public",
    ],
)
