load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "SegmentedControlNode",
    module_name = "SegmentedControlNode",
    srcs = glob([
		"Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/AsyncDisplayKit:AsyncDisplayKit",
        "//submodules/Display:Display",
        "//submodules/TelegramPresentationData:TelegramPresentationData",
    ],
    visibility = [
        "//visibility:public",
    ],
)
