load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TBNetwork",
    module_name = "TBNetwork",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Alamofire:Alamofire",
        "//submodules/SSignalKit/SwiftSignalKit:SwiftSignalKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
