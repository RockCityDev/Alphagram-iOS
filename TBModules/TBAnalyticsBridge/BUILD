load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBAnalyticsBridge",
    module_name = "TBAnalyticsBridge",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//Vendor/Flurry-iOS-SDK:Flurry-iOS-SDK",
        "//submodules/AccountContext:AccountContext",
        #"//Vendor/FirebaseCrashlytics",
    ],
    visibility = [
        "//visibility:public",
    ],
)
