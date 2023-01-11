

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



public final class TulsiProjectInfoExtractor {
  public enum ExtractorError: Error {
    case ruleEntriesFailed(String)
  }
  private let project: TulsiProject
  private let localizedMessageLogger: LocalizedMessageLogger
  var workspaceInfoExtractor: BazelWorkspaceInfoExtractorProtocol

  public var bazelURL: URL {
    get { return workspaceInfoExtractor.bazelURL as URL }
    set { workspaceInfoExtractor.bazelURL = newValue }
  }

  public var bazelExecutionRoot: String {
    return workspaceInfoExtractor.bazelExecutionRoot
  }

  public var bazelOutputBase: String {
    return workspaceInfoExtractor.bazelOutputBase
  }

  public var workspaceRootURL: URL {
    return workspaceInfoExtractor.workspaceRootURL
  }

  public init(bazelURL: URL,
              project: TulsiProject) {
    self.project = project
    let bundle = Bundle(for: type(of: self))
    localizedMessageLogger = LocalizedMessageLogger(bundle: bundle)

    workspaceInfoExtractor = BazelWorkspaceInfoExtractor(bazelURL: bazelURL,
                                                         workspaceRootURL: project.workspaceRootURL,
                                                         localizedMessageLogger: localizedMessageLogger)
  }

  public func extractTargetRules() -> [RuleInfo] {
    return workspaceInfoExtractor.extractRuleInfoFromProject(project)
  }

  public func ruleEntriesForInfos(_ infos: [RuleInfo],
                                  startupOptions: TulsiOption,
                                  extraStartupOptions: TulsiOption,
                                  buildOptions: TulsiOption,
                                  compilationModeOption: TulsiOption,
                                  platformConfigOption: TulsiOption,
                                  prioritizeSwiftOption: TulsiOption,
                                  use64BitWatchSimulatorOption: TulsiOption,
                                  features: Set<BazelSettingFeature>) throws -> RuleEntryMap {
    return try ruleEntriesForLabels(infos.map({ $0.label }),
                                    startupOptions: startupOptions,
                                    extraStartupOptions: extraStartupOptions,
                                    buildOptions: buildOptions,
                                    compilationModeOption: compilationModeOption,
                                    platformConfigOption: platformConfigOption,
                                    prioritizeSwiftOption: prioritizeSwiftOption,
                                    use64BitWatchSimulatorOption: use64BitWatchSimulatorOption,
                                    features: features)
  }

  public func ruleEntriesForLabels(_ labels: [BuildLabel],
                                   startupOptions: TulsiOption,
                                   extraStartupOptions: TulsiOption,
                                   buildOptions: TulsiOption,
                                   compilationModeOption: TulsiOption,
                                   platformConfigOption: TulsiOption,
                                   prioritizeSwiftOption: TulsiOption,
                                   use64BitWatchSimulatorOption: TulsiOption,
                                   features: Set<BazelSettingFeature>) throws -> RuleEntryMap {
    do {
      return try workspaceInfoExtractor.ruleEntriesForLabels(labels,
                                                             startupOptions: startupOptions,
                                                             extraStartupOptions: extraStartupOptions,
                                                             buildOptions: buildOptions,
                                                             compilationModeOption: compilationModeOption,
                                                             platformConfigOption: platformConfigOption,
                                                             prioritizeSwiftOption: prioritizeSwiftOption,
                                                             use64BitWatchSimulatorOption: use64BitWatchSimulatorOption,
                                                             features: features)
    } catch BazelWorkspaceInfoExtractorError.aspectExtractorFailed(let info) {
      throw ExtractorError.ruleEntriesFailed(info)
    }
  }

  public func extractBuildfiles(_ targets: [BuildLabel]) -> Set<BuildLabel> {
    return workspaceInfoExtractor.extractBuildfiles(targets)
  }
}
