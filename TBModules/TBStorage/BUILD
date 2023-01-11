load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
#  tg
swift_library(
    name = "TBStorage",
    module_name = "TBStorage",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//Vendor/HandyJSON:HandyJSON",
    ],
    visibility = [
        "//visibility:public",
    ],
)
