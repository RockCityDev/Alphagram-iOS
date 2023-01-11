

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class BazelSettingsProviderTests: XCTestCase {
  let bazel = "/path/to/bazel"
  let bazelExecRoot = "__MOCK_EXEC_ROOT__"
  let bazelOutputBase = "__MOCK_OUTPUT_BASE__"
  let features = Set<BazelSettingFeature>()
  let buildRuleEntries = Set<RuleEntry>()
  let bazelSettingsProvider = BazelSettingsProvider(universalFlags: BazelFlags())

  func testBazelBuildSettingsProviderForWatchOS() {
    let options = TulsiOptionSet()
    let settings = bazelSettingsProvider.buildSettings(
      bazel: bazel,
      bazelExecRoot: bazelExecRoot,
      bazelOutputBase: bazelOutputBase,
      options: options,
      features: features,
      buildRuleEntries: buildRuleEntries)

    let expectedFlag = "--watchos_cpus=armv7k,arm64_32"
    let expectedIdentifiers = Set(["watchos_armv7k", "watchos_arm64_32", "ios_arm64", "ios_arm64e"])
    
    for (identifier, flags) in settings.platformConfigurationFlags {
      if expectedIdentifiers.contains(identifier) {
        XCTAssert(
          flags.contains(expectedFlag),
          "\(expectedFlag) flag was not set for \(identifier).")
      } else {
        XCTAssert(
          !flags.contains(expectedFlag),
          "\(expectedFlag) flag was unexpectedly set for \(identifier).")
      }
    }
  }
}
