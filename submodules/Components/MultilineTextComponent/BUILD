load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MultilineTextComponent",
    module_name = "MultilineTextComponent",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        #"-warnings-as-errors",
    ],
    deps = [
        "//submodules/Display:Display",
        "//submodules/ComponentFlow:ComponentFlow",
        "//submodules/Markdown:Markdown",
    ],
    visibility = [
        "//visibility:public",
    ],
)
