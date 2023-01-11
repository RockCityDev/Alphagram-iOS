

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation




final class BazelWorkspaceInfoExtractor: BazelWorkspaceInfoExtractorProtocol {
  var bazelURL: URL {
    get { return queryExtractor.bazelURL as URL }
    set {
      queryExtractor.bazelURL = newValue
      aspectExtractor.bazelURL = newValue
    }
  }

  
  var bazelBinPath: String {
    return workspacePathInfoFetcher.getBazelBinPath()
  }

  
  var bazelExecutionRoot: String {
    return workspacePathInfoFetcher.getExecutionRoot()
  }

  
  var bazelOutputBase: String {
    return workspacePathInfoFetcher.getOutputBase()
  }

  
  let bazelSettingsProvider: BazelSettingsProviderProtocol

  
  let workspaceRootURL: URL

  
  private let workspacePathInfoFetcher: BazelWorkspacePathInfoFetcher

  private let aspectExtractor: BazelAspectInfoExtractor
  private let queryExtractor: BazelQueryInfoExtractor

  
  private var ruleEntryCache = RuleEntryMap()

  init(bazelURL: URL, workspaceRootURL: URL, localizedMessageLogger: LocalizedMessageLogger) {
    let universalFlags: BazelFlags
    
    if let applicationSupport = ApplicationSupport() {
      let tulsiVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "UNKNOWN"
      let aspectPath = try! applicationSupport.copyTulsiAspectFiles(tulsiVersion: tulsiVersion)
      universalFlags = BazelFlags(
        
        build: ["--override_repository=tulsi=\(aspectPath)"]
      )
    } else {  
      let bundle = Bundle(for: type(of: self))
      let bazelWorkspace =
        bundle.url(forResource: "WORKSPACE", withExtension: nil)!.deletingLastPathComponent()
      universalFlags = BazelFlags(build: ["--override_repository=tulsi=\(bazelWorkspace.path)"])
    }

    bazelSettingsProvider = BazelSettingsProvider(universalFlags: universalFlags)
    workspacePathInfoFetcher = BazelWorkspacePathInfoFetcher(bazelURL: bazelURL,
                                                             workspaceRootURL: workspaceRootURL,
                                                             bazelUniversalFlags: universalFlags,
                                                             localizedMessageLogger: localizedMessageLogger)

    let executionRootURL =  URL(fileURLWithPath: workspacePathInfoFetcher.getExecutionRoot(),
                                isDirectory: false)
    aspectExtractor = BazelAspectInfoExtractor(bazelURL: bazelURL,
                                               workspaceRootURL: workspaceRootURL,
                                               executionRootURL: executionRootURL,
                                               bazelSettingsProvider: bazelSettingsProvider,
                                               localizedMessageLogger: localizedMessageLogger)
    queryExtractor = BazelQueryInfoExtractor(bazelURL: bazelURL,
                                             workspaceRootURL: workspaceRootURL,
                                             bazelUniversalFlags: universalFlags,
                                             localizedMessageLogger: localizedMessageLogger)
    self.workspaceRootURL = workspaceRootURL
  }

  

  func extractRuleInfoFromProject(_ project: TulsiProject) -> [RuleInfo] {
    return queryExtractor.extractTargetRulesFromPackages(project.bazelPackages)
  }

  func ruleEntriesForLabels(_ labels: [BuildLabel],
                            startupOptions: TulsiOption,
                            extraStartupOptions: TulsiOption,
                            buildOptions: TulsiOption,
                            compilationModeOption: TulsiOption,
                            platformConfigOption: TulsiOption,
                            prioritizeSwiftOption: TulsiOption,
                            use64BitWatchSimulatorOption: TulsiOption,
                            features: Set<BazelSettingFeature>) throws -> RuleEntryMap {
    func isLabelMissing(_ label: BuildLabel) -> Bool {
      return !ruleEntryCache.hasAnyRuleEntry(withBuildLabel: label)
    }
    let missingLabels = labels.filter(isLabelMissing)
    if missingLabels.isEmpty { return ruleEntryCache }

    let commandLineSplitter = CommandLineSplitter()
    func splitOptionString(_ options: String?) -> [String] {
      guard let options = options else { return [] }
      return commandLineSplitter.splitCommandLine(options) ?? []
    }

    let startupOptions = splitOptionString(startupOptions.commonValue) + splitOptionString(extraStartupOptions.commonValue)
    let buildOptions = splitOptionString(buildOptions.commonValue)
    let compilationMode = compilationModeOption.commonValue
    let platformConfig = platformConfigOption.commonValue
    let prioritizeSwift = prioritizeSwiftOption.commonValueAsBool

    if let use64BitWatchSimulatorOption = use64BitWatchSimulatorOption.commonValueAsBool {
      PlatformConfiguration.use64BitWatchSimulator = use64BitWatchSimulatorOption
    }

    do {
      let ruleEntryMap =
        try aspectExtractor.extractRuleEntriesForLabels(labels,
                                                        startupOptions: startupOptions,
                                                        buildOptions: buildOptions,
                                                        compilationMode: compilationMode,
                                                        platformConfig: platformConfig,
                                                        prioritizeSwift: prioritizeSwift,
                                                        features: features)
      ruleEntryCache = RuleEntryMap(ruleEntryMap)
    } catch BazelAspectInfoExtractor.ExtractorError.buildFailed {
      throw BazelWorkspaceInfoExtractorError.aspectExtractorFailed("Bazel aspects could not be built.")
    }

    return ruleEntryCache
  }

  func extractBuildfiles<T: Collection>(_ forTargets: T) -> Set<BuildLabel> where T.Iterator.Element == BuildLabel {
    return queryExtractor.extractBuildfiles(forTargets)
  }

  func logQueuedInfoMessages() {
    queryExtractor.logQueuedInfoMessages()
    aspectExtractor.logQueuedInfoMessages()
  }

  func hasQueuedInfoMessages() -> Bool {
    return aspectExtractor.hasQueuedInfoMessages || queryExtractor.hasQueuedInfoMessages
  }
}
