

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

enum BazelWorkspaceInfoExtractorError: Error {
  case aspectExtractorFailed(String)
}


protocol BazelWorkspaceInfoExtractorProtocol {
  
  func extractRuleInfoFromProject(_ project: TulsiProject) -> [RuleInfo]

  
  
  
  func ruleEntriesForLabels(_ labels: [BuildLabel],
                            startupOptions: TulsiOption,
                            extraStartupOptions: TulsiOption,
                            buildOptions: TulsiOption,
                            compilationModeOption: TulsiOption,
                            platformConfigOption: TulsiOption,
                            prioritizeSwiftOption: TulsiOption,
                            use64BitWatchSimulatorOption: TulsiOption,
                            features: Set<BazelSettingFeature>) throws -> RuleEntryMap

  
  
  func extractBuildfiles<T: Collection>(_ forTargets: T) -> Set<BuildLabel> where T.Iterator.Element == BuildLabel

  
  func logQueuedInfoMessages()

  
  func hasQueuedInfoMessages() -> Bool

  
  var bazelURL: URL {get set}

  
  var bazelBinPath: String {get}

  
  var bazelExecutionRoot: String {get}

  
  var bazelOutputBase: String {get}

  
  var workspaceRootURL: URL {get}

  
  var bazelSettingsProvider: BazelSettingsProviderProtocol {get}
}
