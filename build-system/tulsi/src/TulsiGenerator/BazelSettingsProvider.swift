

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation







public enum BazelSettingFeature: Hashable, Pythonable {

  
  
  
  
  
  
  case DebugPathNormalization

  
  
  case SwiftForcesdSYMs

  
  
  
  
  
  
  
  case TreeArtifactOutputs

  
  
  public var stringValue: String {
    switch self {
      case .DebugPathNormalization:
        return "DebugPathNormalization"
      case .SwiftForcesdSYMs:
        return "SwiftForcesdSYMs"
      case .TreeArtifactOutputs:
        return "TreeArtifactOutputs"
    }
  }

  public var hashValue: Int {
    return stringValue.hashValue
  }

  public static func ==(lhs: BazelSettingFeature, rhs: BazelSettingFeature) -> Bool {
    return lhs.stringValue == rhs.stringValue
  }

  public var supportsSwift: Bool {
    switch self {
      case .DebugPathNormalization:
        
        
        return true
      case .SwiftForcesdSYMs:
        return true
      case .TreeArtifactOutputs:
        return true
    }
  }

  public var supportsNonSwift: Bool {
    switch self {
      case .DebugPathNormalization:
        return true
      case .SwiftForcesdSYMs:
        return false
      case .TreeArtifactOutputs:
        return true
    }
  }

  
  public var startupFlags: [String] {
    return []
  }

  
  public var buildFlags: [String] {
    switch self {
      case .DebugPathNormalization: return ["--features=debug_prefix_map_pwd_is_dot"]
      case .SwiftForcesdSYMs: return ["--apple_generate_dsym"]
      case .TreeArtifactOutputs: return ["--define=apple.experimental.tree_artifact_outputs=1"]
    }
  }

  func toPython(_ indentation: String) -> String {
    return stringValue.toPython(indentation)
  }
}


protocol BazelSettingsProviderProtocol {
  
  var universalFlags: BazelFlags { get }

  
  func tulsiFlags(hasSwift: Bool,
                  options: TulsiOptionSet?,
                  features: Set<BazelSettingFeature>) -> BazelFlagsSet

  
  func buildSettings(bazel: String,
                     bazelExecRoot: String,
                     bazelOutputBase: String,
                     options: TulsiOptionSet,
                     features: Set<BazelSettingFeature>,
                     buildRuleEntries: Set<RuleEntry>) -> BazelBuildSettings
}

class BazelSettingsProvider: BazelSettingsProviderProtocol {

  
  static let tulsiDebugFlags = BazelFlags(build: ["--compilation_mode=dbg"])

  
  static let tulsiReleaseFlags = BazelFlags(build: [
      "--compilation_mode=opt",
      "--strip=always",
      "--apple_generate_dsym",
  ])

  
  static let tulsiCommonNonCacheableFlags = BazelFlags(build: [
      "--define=apple.add_debugger_entitlement=1",
      "--define=apple.propagate_embedded_extra_outputs=1",
  ])

  
  static let tulsiCacheableFlags = BazelFlagsSet(buildFlags: ["--announce_rc"])

  
  static let tulsiNonCacheableFlags = BazelFlagsSet(debug: tulsiDebugFlags,
                                                    release: tulsiReleaseFlags,
                                                    common: tulsiCommonNonCacheableFlags)

  
  let universalFlags: BazelFlags

  
  let cacheableFlags: BazelFlagsSet

  
  let nonCacheableFlags: BazelFlagsSet

  
  let swiftFlags: BazelFlagsSet

  
  let nonSwiftFlags: BazelFlagsSet

  public convenience init(universalFlags: BazelFlags) {
    self.init(universalFlags: universalFlags,
              cacheableFlags: BazelSettingsProvider.tulsiCacheableFlags,
              nonCacheableFlags: BazelSettingsProvider.tulsiNonCacheableFlags,
              swiftFlags: BazelFlagsSet(),
              nonSwiftFlags: BazelFlagsSet())
  }

  public init(universalFlags: BazelFlags,
              cacheableFlags: BazelFlagsSet,
              nonCacheableFlags: BazelFlagsSet,
              swiftFlags: BazelFlagsSet,
              nonSwiftFlags: BazelFlagsSet) {
    self.universalFlags = universalFlags
    self.cacheableFlags = cacheableFlags
    self.nonCacheableFlags = nonCacheableFlags
    self.swiftFlags = swiftFlags
    self.nonSwiftFlags = nonSwiftFlags
  }

  func tulsiFlags(hasSwift: Bool,
                  options: TulsiOptionSet?,
                  features: Set<BazelSettingFeature>) -> BazelFlagsSet {
    let optionFlags: BazelFlagsSet
    if let options = options {
      optionFlags = optionsBasedFlags(options)
    } else {
      optionFlags = BazelFlagsSet()
    }
    let languageFlags = (hasSwift ? swiftFlags : nonSwiftFlags) + featureFlags(features,
                                                                               hasSwift: hasSwift)
    return cacheableFlags + optionFlags + BazelFlagsSet(common: universalFlags) +
      nonCacheableFlags + languageFlags
  }

  
  func featureFlags(_ features: Set<BazelSettingFeature>, hasSwift: Bool) -> BazelFlagsSet {
    let validFeatures = features.filter { return hasSwift ? $0.supportsSwift : $0.supportsNonSwift }
    let sortedFeatures = validFeatures.sorted { (a, b) -> Bool in
      return a.stringValue > b.stringValue
    }

    let startupFlags = sortedFeatures.reduce(into: []) { (arr, feature) in
      arr.append(contentsOf: feature.startupFlags)
    }
    let buildFlags = sortedFeatures.reduce(into: []) { (arr, feature) in
      arr.append(contentsOf: feature.buildFlags)
    }
    return BazelFlagsSet(startupFlags: startupFlags, buildFlags: buildFlags)
  }

  
  func featureNames(_ features: Set<BazelSettingFeature>, hasSwift: Bool) -> [String] {
    let validFeatures = features.filter { return hasSwift ? $0.supportsSwift : $0.supportsNonSwift }
    return validFeatures.sorted { (a, b) -> Bool in
      return a.stringValue > b.stringValue
    }.map { $0.stringValue }
  }

  
  
  
  
  func optionsBasedFlags(_ options: TulsiOptionSet) -> BazelFlagsSet {
    var configBasedTulsiFlags = [String]()
    if let continueBuildingAfterError = options[.BazelContinueBuildingAfterError].commonValueAsBool,
      continueBuildingAfterError {
      configBasedTulsiFlags.append("--keep_going")
    }
    return BazelFlagsSet(buildFlags: configBasedTulsiFlags)
  }

  func buildSettings(bazel: String,
                     bazelExecRoot: String,
                     bazelOutputBase: String,
                     options: TulsiOptionSet,
                     features: Set<BazelSettingFeature>,
                     buildRuleEntries: Set<RuleEntry>) -> BazelBuildSettings {
    let projDefaultSettings = getProjDefaultSettings(options)
    var targetSettings = [String: BazelFlagsSet]()

    
    var labels = Set<String>()
    labels.formUnion(getTargets(options, .BazelBuildOptionsDebug))
    labels.formUnion(getTargets(options, .BazelBuildOptionsRelease))
    labels.formUnion(getTargets(options, .BazelBuildStartupOptionsDebug))
    labels.formUnion(getTargets(options, .BazelBuildStartupOptionsRelease))

    for lbl in labels {
      guard let settings = getTargetSettings(options, lbl, defaultValue: projDefaultSettings) else {
        continue
      }
      targetSettings[lbl] = settings
    }

    let swiftRuleEntries = buildRuleEntries.filter {
        $0.attributes[.has_swift_dependency] as? Bool ?? false
    }
    let swiftTargets = Set(swiftRuleEntries.map { $0.label.value })

    let tulsiSwiftFlags = swiftFlags + featureFlags(features, hasSwift: true)
    let tulsiNonSwiftFlagSet = nonSwiftFlags + featureFlags(features, hasSwift: false)
    let swiftFeatures = featureNames(features, hasSwift: true)
    let nonSwiftFeatures = featureNames(features, hasSwift: false)

    let defaultConfig: PlatformConfiguration
    if let identifier = options[.ProjectGenerationPlatformConfiguration].commonValue,
       let parsedConfig = PlatformConfiguration(identifier: identifier) {
      defaultConfig = parsedConfig
    } else {
      defaultConfig = PlatformConfiguration.defaultConfiguration
    }

    return BazelBuildSettings(bazel: bazel,
                              bazelExecRoot: bazelExecRoot,
                              bazelOutputBase: bazelOutputBase,
                              defaultPlatformConfigIdentifier: defaultConfig.identifier,
                              platformConfigurationFlags: nil,
                              swiftTargets: swiftTargets,
                              tulsiCacheAffectingFlagsSet: BazelFlagsSet(common: universalFlags) + nonCacheableFlags,
                              tulsiCacheSafeFlagSet: cacheableFlags + optionsBasedFlags(options),
                              tulsiSwiftFlagSet: tulsiSwiftFlags,
                              tulsiNonSwiftFlagSet: tulsiNonSwiftFlagSet,
                              swiftFeatures: swiftFeatures,
                              nonSwiftFeatures: nonSwiftFeatures,
                              projDefaultFlagSet: projDefaultSettings,
                              projTargetFlagSets: targetSettings)
  }


  private func getValue(_ options: TulsiOptionSet, _ key: TulsiOptionKey, defaultValue: String)
      -> String {
    return options[key].commonValue ?? defaultValue
  }

  private func getTargets(_ options: TulsiOptionSet, _ key: TulsiOptionKey) -> [String] {
    guard let targetValues = options[key].targetValues else { return [String]() }
    return Array(targetValues.keys)
  }

  private func getTargetValue(_ options: TulsiOptionSet,
                              _ key: TulsiOptionKey,
                              _ target: String,
                              defaultValue: String) -> String {
    return options[key, target] ?? defaultValue
  }

  private func getProjDefaultSettings(_ options: TulsiOptionSet) -> BazelFlagsSet {
    let debugStartup = getValue(options, .BazelBuildStartupOptionsDebug, defaultValue: "")
    let debugBuild = getValue(options, .BazelBuildOptionsDebug, defaultValue: "")
    let releaseStartup = getValue(options, .BazelBuildStartupOptionsRelease, defaultValue: "")
    let releaseBuild = getValue(options, .BazelBuildOptionsRelease, defaultValue: "")

    let debugFlags = BazelFlags(startupStr: debugStartup, buildStr: debugBuild)
    let releaseFlags = BazelFlags(startupStr: releaseStartup, buildStr: releaseBuild)

    return BazelFlagsSet(debug: debugFlags, release: releaseFlags)
  }

  private func getTargetSettings(_ options: TulsiOptionSet,
                                 _ label: String,
                                 defaultValue: BazelFlagsSet) -> BazelFlagsSet? {
    let debugStartup = getTargetValue(options, .BazelBuildStartupOptionsDebug, label, defaultValue: "")
    let debugBuild = getTargetValue(options, .BazelBuildOptionsDebug, label, defaultValue: "")
    let releaseStartup = getTargetValue(options, .BazelBuildStartupOptionsRelease, label, defaultValue: "")
    let releaseBuild = getTargetValue(options, .BazelBuildOptionsRelease, label, defaultValue: "")

    let debugFlags = BazelFlags(startupStr: debugStartup, buildStr: debugBuild)
    let releaseFlags = BazelFlags(startupStr: releaseStartup, buildStr: releaseBuild)

    
    guard debugFlags != defaultValue.debug
      && releaseFlags != defaultValue.release else {
        return nil
    }
    return BazelFlagsSet(debug: debugFlags, release: releaseFlags)
  }

}

