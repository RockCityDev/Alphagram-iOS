load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
# TB   
    name = "TBOpenSea",
    module_name = "TBOpenSea",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//TBModules/TBStorage:TBStorage",
        "//TBModules/TBAccount:TBAccount",
        "//Vendor/HandyJSON:HandyJSON",
        "//Vendor/Alamofire:Alamofire",
        "//Vendor/ProgressHUD:ProgressHUD",
    ],

    visibility = [
        "//visibility:public",
    ],
)
