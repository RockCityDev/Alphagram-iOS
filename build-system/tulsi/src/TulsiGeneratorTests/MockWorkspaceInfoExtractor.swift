

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

@testable import TulsiGenerator

class MockBazelSettingsProvider: BazelSettingsProviderProtocol {

  var universalFlags: BazelFlags {
    return BazelFlags()
  }

  func tulsiFlags(
    hasSwift: Bool,
    options: TulsiOptionSet?,
    features: Set<BazelSettingFeature>
  ) -> BazelFlagsSet {
    return BazelFlagsSet()
  }

  func buildSettings(
    bazel: String,
    bazelExecRoot: String,
    bazelOutputBase: String,
    options: TulsiOptionSet,
    features: Set<BazelSettingFeature>,
    buildRuleEntries: Set<RuleEntry>
  ) -> BazelBuildSettings {
    return BazelBuildSettings(
      bazel: bazel,
      bazelExecRoot: bazelExecRoot,
      bazelOutputBase: bazelOutputBase,
      defaultPlatformConfigIdentifier: "",
      platformConfigurationFlags: nil,
      swiftTargets: [],
      tulsiCacheAffectingFlagsSet: BazelFlagsSet(),
      tulsiCacheSafeFlagSet: BazelFlagsSet(),
      tulsiSwiftFlagSet: BazelFlagsSet(),
      tulsiNonSwiftFlagSet: BazelFlagsSet(),
      swiftFeatures: [],
      nonSwiftFeatures: [],
      projDefaultFlagSet: BazelFlagsSet(),
      projTargetFlagSets: [:])
  }
}

class MockWorkspaceInfoExtractor: BazelWorkspaceInfoExtractorProtocol {

  let bazelSettingsProvider: BazelSettingsProviderProtocol = MockBazelSettingsProvider()

  var labelToRuleEntry = [BuildLabel: RuleEntry]()

  
  
  var invalidLabels = Set<BuildLabel>()

  var bazelURL = URL(fileURLWithPath: "")
  var bazelBinPath = "bazel-bin"
  var bazelExecutionRoot
    = "/private/var/tmp/_bazel_localhost/1234567890abcdef1234567890abcdef/execroot/workspace_dir"
  var bazelOutputBase
    = "/private/var/tmp/_bazel_localhost/1234567890abcdef1234567890abcdef"
  var workspaceRootURL = URL(fileURLWithPath: "")

  func extractRuleInfoFromProject(_ project: TulsiProject) -> [RuleInfo] {
    return []
  }

  func ruleEntriesForLabels(
    _ labels: [BuildLabel],
    startupOptions: TulsiOption,
    extraStartupOptions: TulsiOption,
    buildOptions: TulsiOption,
    compilationModeOption: TulsiOption,
    platformConfigOption: TulsiOption,
    prioritizeSwiftOption: TulsiOption,
    use64BitWatchSimulatorOption: TulsiOption,
    features: Set<BazelSettingFeature>
  ) throws -> RuleEntryMap {
    invalidLabels.removeAll(keepingCapacity: true)
    let ret = RuleEntryMap()
    for label in labels {
      guard let entry = labelToRuleEntry[label] else {
        invalidLabels.insert(label)
        continue
      }
      ret.insert(ruleEntry: entry)
    }
    return ret
  }

  func extractBuildfiles<T: Collection>(_ forTargets: T) -> Set<BuildLabel>
  where T.Iterator.Element == BuildLabel {
    return Set()
  }

  func logQueuedInfoMessages() {}

  func hasQueuedInfoMessages() -> Bool { return false }
}
