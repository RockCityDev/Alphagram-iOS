# This Makefile does some odd things to setup testing conditions
# and install Bazel.
# Please see the `README` for regular usage

BAZEL=../../tools/bazel

# Override the repository to point at the source. It does a source build of the
# current code.
# TODO: there's an issue with non hermetic headers in the PINRemoteImage example

# Some examples require out of band loading
pod_test:
	pod --version

# bazel run @rules_pods//:update_pods -- --src_root $PWD
vendor:
	$(BAZEL) run @rules_pods//:update_pods -- --src_root $PWD

update_pod:
	pod install

# This command generates a workspace from a Podfile
gen_pod_deps:
	../../bin/RepoTools generate_workspace > podfile_deps.py

