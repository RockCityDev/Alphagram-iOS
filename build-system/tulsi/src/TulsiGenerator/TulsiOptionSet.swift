

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation





public enum TulsiOptionKey: String {
  case
      
      ALWAYS_SEARCH_USER_PATHS,

      
      CLANG_CXX_LANGUAGE_STANDARD,

      
      BazelPath,
      
      
      
      SuppressSwiftUpdateCheck,
      
      SwiftForcesdSYMs,
      
      
      
      TreeArtifactOutputs,
      
      WorkspaceRootPath,

      
      CommandlineArguments,

      
      EnvironmentVariables,

      
      BazelContinueBuildingAfterError,

      
      IncludeBuildSources,

      
      ProjectGenerationCompilationMode,

      
      ProjectGenerationPlatformConfiguration,

      
      ProjectGenerationBazelStartupOptions,

      
      ImprovedImportAutocompletionFix,

      
      GenerateRunfiles,

      
      PathFiltersApplyToTestSources,

      
      ProjectPrioritizesSwift,

      
      
      
      
      Use64BitWatchSimulator,

      
      UseLegacyBuildSystem,

      
      DisableCustomLLDBInit,

      
      PreBuildPhaseRunScript,

      
      PostBuildPhaseRunScript,

      
      UseBazelCacheReader

  
  case BazelBuildOptionsDebug,
       BazelBuildOptionsRelease

  
  case BazelBuildStartupOptionsDebug,
       BazelBuildStartupOptionsRelease

  
  case BuildActionPreActionScript,
       LaunchActionPreActionScript,
       TestActionPreActionScript

  
  case BuildActionPostActionScript,
       LaunchActionPostActionScript,
       TestActionPostActionScript
}



public enum TulsiOptionKeyGroup: String {
  case BazelBuildOptions,
       BazelBuildStartupOptions,
       PreActionScriptOptions,
       PostActionScriptOptions
}



public class TulsiOptionSet: Equatable {
  
  static let DescriptionStringKeySuffix = "_DESC"

  
  static let PersistenceKey = "optionSet"

  typealias PersistenceType = [String: TulsiOption.PersistenceType]

  static let OptionKeyGroups: [TulsiOptionKey: TulsiOptionKeyGroup] = [
      .ProjectGenerationBazelStartupOptions: .BazelBuildStartupOptions,
      .BazelBuildOptionsDebug: .BazelBuildOptions,
      .BazelBuildOptionsRelease: .BazelBuildOptions,
      .BazelBuildStartupOptionsDebug: .BazelBuildStartupOptions,
      .BazelBuildStartupOptionsRelease: .BazelBuildStartupOptions,
      .BuildActionPreActionScript: .PreActionScriptOptions,
      .LaunchActionPreActionScript: .PreActionScriptOptions,
      .TestActionPreActionScript: .PreActionScriptOptions,
      .BuildActionPostActionScript: .PostActionScriptOptions,
      .LaunchActionPostActionScript: .PostActionScriptOptions,
      .TestActionPostActionScript: .PostActionScriptOptions
  ]

  public var allVisibleOptions = [TulsiOptionKey: TulsiOption]()
  var options = [TulsiOptionKey: TulsiOption]() {
    didSet {
      allVisibleOptions = [TulsiOptionKey: TulsiOption]()
      for (key, option) in options {
        if !option.optionType.contains(.Hidden) {
          allVisibleOptions[key] = option
        }
      }
    }
  }
  var optionKeyGroupInfo = [TulsiOptionKeyGroup: (displayName: String, description: String)]()

  public subscript(optionKey: TulsiOptionKey) -> TulsiOption {
    return options[optionKey]!
  }

  public subscript(optionKey: TulsiOptionKey, target: String) -> String? {
    return options[optionKey]?.valueForTarget(target)
  }

  static func getOptionsFromContainerDictionary(_ dict: [String: Any]) -> PersistenceType? {
    return dict[TulsiOptionSet.PersistenceKey] as? PersistenceType
  }

  public init(withInheritanceEnabled inherit: Bool = false) {
    let bundle = Bundle(for: type(of: self))
    populateOptionsWithBundle(bundle, withInheritAsDefault: inherit)
    populateOptionGroupInfoWithBundle(bundle)
  }

  public convenience init(fromDictionary dict: [String: Any]) {
    self.init()

    guard let persistedOptions = dict as? PersistenceType else {
      assertionFailure("Options dictionary is not of the expected type")
      return
    }

    for (key, option) in options {
      if let value = persistedOptions[key.rawValue] {
        option.deserialize(value)
      }
    }
  }

  
  
  public func optionSetByInheritingFrom(_ parent: TulsiOptionSet) -> TulsiOptionSet {
    var resolvedOptions = [TulsiOptionKey: TulsiOption]()
    for (key, opt) in options {
      guard let parentOption = parent.options[key] else {
        resolvedOptions[key] = opt
        continue
      }
      resolvedOptions[key] = TulsiOption(resolvingValuesFrom: opt, byInheritingFrom: parentOption)
    }

    let resolvedSet = TulsiOptionSet()
    resolvedSet.options = resolvedOptions
    return resolvedSet
  }

  func saveShareableOptionsIntoDictionary(_ dict: inout [String: Any]) {
    let serialized = saveToDictionary() {
      !$1.optionType.contains(.PerUserOnly)
    }
    dict[TulsiOptionSet.PersistenceKey] = serialized
  }

  func savePerUserOptionsIntoDictionary(_ dict: inout [String: Any]) {
    let serialized = saveToDictionary() {
      return $1.optionType.contains(.PerUserOnly)
    }
    dict[TulsiOptionSet.PersistenceKey] = serialized
  }

  func saveAllOptionsIntoDictionary(_ dict: inout [String: AnyObject]) {
    let serialized = saveToDictionary() { (_, _) in return true }
    dict[TulsiOptionSet.PersistenceKey] = serialized as AnyObject?
  }

  public func groupInfoForOptionKey(_ key: TulsiOptionKey) -> (TulsiOptionKeyGroup, displayName: String, description: String)? {
    guard let keyGroup = TulsiOptionSet.OptionKeyGroups[key] else { return nil }
    guard let (displayName, description) = optionKeyGroupInfo[keyGroup] else {
      assertionFailure("Missing group information for group key \(keyGroup)")
      return (keyGroup, "\(keyGroup)", "")
    }
    return (keyGroup, displayName, description)
  }

  
  func commonBuildSettings() -> [String: String] {
    
    
    var buildSettings = [
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
    ]

    for (key, opt) in options.filter({ $1.optionType.contains(.BuildSetting) }) {
      buildSettings[key.rawValue] = opt.commonValue!
    }
    return buildSettings
  }

  
  
  func buildSettingsForTarget(_ target: String) -> [String: String] {
    var buildSettings = [String: String]()
    for (key, opt) in options.filter({ $1.optionType.contains(.TargetSpecializableBuildSetting) }) {
      if let val = opt.valueForTarget(target, inherit: false) {
        buildSettings[key.rawValue] = val
      }
    }
    return buildSettings
  }

  

  
  var useLegacyBuildSystem: Bool {
    return self[.UseLegacyBuildSystem].commonValueAsBool ?? true
  }

  

  private func saveToDictionary(_ filter: (TulsiOptionKey, TulsiOption) -> Bool) -> PersistenceType {
    var serialized = PersistenceType()
    for (key, option) in options.filter(filter) {
      if let value = option.serialize() {
        serialized[key.rawValue] = value
      }
    }
    return serialized
  }

  private func populateOptionsWithBundle(_ bundle: Bundle, withInheritAsDefault inherit: Bool) {
    func addOption(_ optionKey: TulsiOptionKey, valueType: TulsiOption.ValueType, optionType: TulsiOption.OptionType, defaultValue: String?) {
      let key = optionKey.rawValue
      let displayName = bundle.localizedString(forKey: key, value: nil, table: "Options")
      let descriptionKey = key + TulsiOptionSet.DescriptionStringKeySuffix
      var description = bundle.localizedString(forKey: descriptionKey, value: nil, table: "Options")
      if description == descriptionKey { description = "" }

      let opt = TulsiOption(displayName: displayName,
                            userDescription: description,
                            valueType: valueType,
                            optionType: optionType,
                            defaultValue: defaultValue)
      if inherit && optionType.contains(.SupportsInheritKeyword) {
        opt.projectValue = TulsiOption.InheritKeyword
      }
      options[optionKey] = opt
    }

    func addBoolOption(_ optionKey: TulsiOptionKey, _ optionType: TulsiOption.OptionType, _ defaultValue: Bool = false) {
      let val = defaultValue ? TulsiOption.BooleanTrueValue : TulsiOption.BooleanFalseValue
      addOption(optionKey, valueType: .bool, optionType: optionType, defaultValue: val)
    }

    func addStringOption(_ optionKey: TulsiOptionKey, _ optionType: TulsiOption.OptionType, _ defaultValue: String? = nil) {
      addOption(optionKey, valueType: .string, optionType: optionType, defaultValue: defaultValue)
    }

    func addStringEnumOption(_ optionKey: TulsiOptionKey,
                             _ optionType: TulsiOption.OptionType,
                             _ defaultValue: String,
                             _ values: [String]) {
      assert(values.contains(defaultValue), "Invalid enum for \(optionKey.rawValue): " +
          "defaultValue of \"\(defaultValue)\" is not present in enum values: \(values).")
      addOption(optionKey, valueType: .stringEnum(Set(values)),
                optionType: optionType, defaultValue: defaultValue)
    }

    addBoolOption(.ALWAYS_SEARCH_USER_PATHS, .BuildSetting, false)
    addBoolOption(.BazelContinueBuildingAfterError, .Generic, false)
    addStringOption(.BazelBuildOptionsDebug, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.BazelBuildOptionsRelease, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.BazelBuildStartupOptionsDebug, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.BazelBuildStartupOptionsRelease, [.TargetSpecializable, .SupportsInheritKeyword])
    addBoolOption(.SuppressSwiftUpdateCheck, .Generic, true)
    addBoolOption(.IncludeBuildSources, .Generic, false)
    addBoolOption(.ImprovedImportAutocompletionFix, .Generic, true)
    addBoolOption(.GenerateRunfiles, .Generic, false)
    addBoolOption(.PathFiltersApplyToTestSources, .Generic, true)
    addBoolOption(.ProjectPrioritizesSwift, .Generic, false)
    addBoolOption(.SwiftForcesdSYMs, .Generic, false)
    addBoolOption(.TreeArtifactOutputs, .Generic, true)
    addBoolOption(.Use64BitWatchSimulator, .Generic, false)
    addBoolOption(.DisableCustomLLDBInit, .Generic, false)
    addBoolOption(.UseBazelCacheReader, .Generic, false)
    addBoolOption(.UseLegacyBuildSystem, .Generic, true)

    let defaultIdentifier = PlatformConfiguration.defaultConfiguration.identifier
    let platformCPUIdentifiers = PlatformConfiguration.allValidConfigurations.map { $0.identifier }
    addStringEnumOption(.ProjectGenerationPlatformConfiguration, .Generic,
                        defaultIdentifier, platformCPUIdentifiers)
    addStringEnumOption(.ProjectGenerationCompilationMode, .Generic, "dbg", ["dbg", "opt"])
    addStringOption(.ProjectGenerationBazelStartupOptions, [.SupportsInheritKeyword])

    addStringOption(.CommandlineArguments, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.EnvironmentVariables, [.TargetSpecializable, .SupportsInheritKeyword])

    
    
    let cppLanguageStandards = ["compiler-default", "c++98", "gnu++98", "c++11", "gnu++11", "c++14", "gnu++14", "c++17", "gnu++17"]
    addStringEnumOption(.CLANG_CXX_LANGUAGE_STANDARD, .BuildSetting, "gnu++17",  cppLanguageStandards)

    addStringOption(.PreBuildPhaseRunScript, [.TargetSpecializable])
    addStringOption(.PostBuildPhaseRunScript, [.TargetSpecializable])
    addStringOption(.BuildActionPreActionScript, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.LaunchActionPreActionScript, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.TestActionPreActionScript, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.BuildActionPostActionScript, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.LaunchActionPostActionScript, [.TargetSpecializable, .SupportsInheritKeyword])
    addStringOption(.TestActionPostActionScript, [.TargetSpecializable, .SupportsInheritKeyword])

    addStringOption(.BazelPath, [.Hidden, .PerUserOnly])
    addStringOption(.WorkspaceRootPath, [.Hidden, .PerUserOnly])
  }

  private func populateOptionGroupInfoWithBundle(_ bundle: Bundle) {
    for (_, keyGroup) in TulsiOptionSet.OptionKeyGroups {
      if optionKeyGroupInfo[keyGroup] == nil {
        let key = keyGroup.rawValue
        let displayName = NSLocalizedString(key, tableName: "Options", bundle: bundle, comment: "")
        let descriptionKey = key + TulsiOptionSet.DescriptionStringKeySuffix
        let description = NSLocalizedString(descriptionKey, tableName: "Options", bundle: bundle, comment: "")
        optionKeyGroupInfo[keyGroup] = (displayName, description)
      }
    }
  }
}

public func ==(lhs: TulsiOptionSet, rhs: TulsiOptionSet) -> Bool {
  for (key, option) in lhs.options {
    if rhs[key] != option {
      return false
    }
  }
  return true
}
