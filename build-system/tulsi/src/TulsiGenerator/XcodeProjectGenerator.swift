

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



final class XcodeProjectGenerator {
  enum ProjectGeneratorError: Error {
    
    case serializationFailed(String)

    
    case labelAspectFailure(String)

    
    case labelResolutionFailed(Set<BuildLabel>)

    
    case invalidXcodeProjectPath(path: String, reason: String)
  }

  
  
  struct ResourceSourcePathURLs {
    let buildScript: URL  // The script to run on "build" actions.
    let cleanScript: URL  // The script to run on "clean" actions.
    let extraBuildScripts: [URL] 
    let iOSUIRunnerEntitlements: URL  
    let macOSUIRunnerEntitlements: URL  
    let stubInfoPlist: URL  
    let stubIOSAppExInfoPlistTemplate: URL  
    let stubWatchOS2InfoPlist: URL  
    let stubWatchOS2AppExInfoPlist: URL  

    let stubClang: URL   
    let stubSwiftc: URL  
    let stubLd: URL      

    
    
    
    
    
    
    
    
    // "tulsi" package.
    let bazelWorkspaceFile: URL 
    let tulsiPackageFiles: [URL] // Files to copy into the "tulsi" package.
  }

  
  
  private static let TulsiArtifactDirectory = ".tulsi"
  static let ScriptDirectorySubpath = "\(TulsiArtifactDirectory)/Scripts"
  static let BazelDirectorySubpath = "\(TulsiArtifactDirectory)/Bazel"
  static let TulsiPackageName = "tulsi"
  static let UtilDirectorySubpath = "\(TulsiArtifactDirectory)/Utils"
  static let ConfigDirectorySubpath = "\(TulsiArtifactDirectory)/Configs"
  static let ProjectResourcesDirectorySubpath = "\(TulsiArtifactDirectory)/Resources"
  private static let BuildScript = "bazel_build.py"
  private static let SettingsScript = "bazel_build_settings.py"
  private static let CleanScript = "bazel_clean.sh"
  private static let ShellCommandsUtil = "bazel_cache_reader"
  private static let ModuleCachePrunerUtil = "module_cache_pruner"
  private static let ShellCommandsCleanScript = "clean_symbol_cache"
  private static let LLDBInitBootstrapScript = "bootstrap_lldbinit"
  private static let CustomLLDBInit = "lldbinit"
  private static let WorkspaceFile = "WORKSPACE"
  private static let IOSUIRunnerEntitlements = "iOSXCTRunner.entitlements"
  private static let MacOSUIRunnerEntitlements = "macOSXCTRunner.entitlements"
  private static let StubInfoPlistFilename = "StubInfoPlist.plist"
  private static let StubWatchOS2InfoPlistFilename = "StubWatchOS2InfoPlist.plist"
  private static let StubWatchOS2AppExInfoPlistFilename = "StubWatchOS2AppExInfoPlist.plist"

  private static let StubClang = "clang_stub.sh"
  private static let StubSwiftc = "swiftc_stub.py"
  private static let StubLd = "ld_stub.sh"

  private static let CachedExecutionRootFilename = "execroot_path.py"
  private static let DefaultSwiftVersion = "4"
  private static let SupportScriptsPath = "Library/Application Support/Tulsi/Scripts"

  private let workspaceRootURL: URL
  private let config: TulsiGeneratorConfig
  private let localizedMessageLogger: LocalizedMessageLogger
  private let fileManager: FileManager
  private let workspaceInfoExtractor: BazelWorkspaceInfoExtractorProtocol
  private let resourceURLs: ResourceSourcePathURLs
  private let tulsiVersion: String
  private let customLLDBInitFile: String?

  private let pbxTargetGeneratorType: PBXTargetGeneratorProtocol.Type

  
  var writeDataHandler: (URL, Data) throws -> Void = { (outputFileURL: URL, data: Data) in
    try data.write(to: outputFileURL, options: NSData.WritingOptions.atomic)
  }

  
  var usernameFetcher: () -> String = NSUserName

  
  
  var suppressCompilerDefines = false

  
  
  var redactSymlinksToBazelOutput = false

  
  var suppressUpdatingShellCommands = false

  
  var suppressModuleCachePrunerInstallation = false

  
  var suppressModifyingUserDefaults = false

  
  var suppressGeneratingBuildSettings = false

  var cachedDefaultSwiftVersion: String?

  init(workspaceRootURL: URL,
       config: TulsiGeneratorConfig,
       localizedMessageLogger: LocalizedMessageLogger,
       workspaceInfoExtractor: BazelWorkspaceInfoExtractorProtocol,
       resourceURLs: ResourceSourcePathURLs,
       tulsiVersion: String,
       fileManager: FileManager = FileManager.default,
       pbxTargetGeneratorType: PBXTargetGeneratorProtocol.Type = PBXTargetGenerator.self) {
    self.workspaceRootURL = workspaceRootURL
    self.config = config
    self.localizedMessageLogger = localizedMessageLogger
    self.workspaceInfoExtractor = workspaceInfoExtractor
    self.resourceURLs = resourceURLs
    self.tulsiVersion = tulsiVersion
    self.fileManager = fileManager
    self.pbxTargetGeneratorType = pbxTargetGeneratorType
    self.customLLDBInitFile = XcodeProjectGenerator.computeCustomLLDBInitFile(config)
  }

  static private func computeCustomLLDBInitFile(_ config: TulsiGeneratorConfig) -> String?  {
    
    
#if swift(>=5.2)
    if config.options[.DisableCustomLLDBInit].commonValueAsBool != true {
      return
        "$(PROJECT_FILE_PATH)/\(XcodeProjectGenerator.UtilDirectorySubpath)/\(XcodeProjectGenerator.CustomLLDBInit)"
    }
#endif
    return nil
  }

  /// Determines the "best" common SDKROOT for a sequence of RuleEntries.
  static func projectSDKROOT<T>(_ targetRules: T) -> String? where T: Sequence, T.Iterator.Element == RuleEntry {
    var discoveredSDKs = Set<String>()
    for entry in targetRules {
      if let sdkroot = entry.XcodeSDKRoot {
        discoveredSDKs.insert(sdkroot)
      }
    }

    if discoveredSDKs.count == 1 {
      return discoveredSDKs.first!
    }

    if discoveredSDKs.isEmpty {
      
      
      
      
      return "iphoneos"
    }

    if discoveredSDKs == ["iphoneos", "watchos"] {
      
      
      return "iphoneos"
    }

    
    // do not set the SDKROOT. Unfortunately this will cause "My Mac" to be listed as a target
    
    
    
    
    return nil
  }

  
  
  func generateXcodeProjectInFolder(_ outputFolderURL: URL) throws -> URL {
    let generateProfilingToken = localizedMessageLogger.startProfiling("generating_project",
                                                                       context: config.projectName)
    defer { localizedMessageLogger.logProfilingEnd(generateProfilingToken) }
    try validateXcodeProjectPath(outputFolderURL)

    let mainGroup = pbxTargetGeneratorType.mainGroupForOutputFolder(outputFolderURL,
                                                                    workspaceRootURL: workspaceRootURL)

    let projectResourcesDirectory = "${PROJECT_FILE_PATH}/\(XcodeProjectGenerator.ProjectResourcesDirectorySubpath)"
    let plistPaths = StubInfoPlistPaths(
      resourcesDirectory: projectResourcesDirectory,
      defaultStub: "\(projectResourcesDirectory)/\(XcodeProjectGenerator.StubInfoPlistFilename)",
      watchOSStub: "\(projectResourcesDirectory)/\(XcodeProjectGenerator.StubWatchOS2InfoPlistFilename)",
      watchOSAppExStub: "\(projectResourcesDirectory)/\(XcodeProjectGenerator.StubWatchOS2AppExInfoPlistFilename)")

    let stubBinaryDirectory = "$(PROJECT_FILE_PATH)/\(XcodeProjectGenerator.ScriptDirectorySubpath)"
    let binaryPaths = StubBinaryPaths(
      clang: "\(stubBinaryDirectory)/\(XcodeProjectGenerator.StubClang)",
      swiftc: "\(stubBinaryDirectory)/\(XcodeProjectGenerator.StubSwiftc)",
      ld: "\(stubBinaryDirectory)/\(XcodeProjectGenerator.StubLd)")

    let projectInfo = try buildXcodeProjectWithMainGroup(mainGroup,
                                                         stubInfoPlistPaths: plistPaths,
                                                         stubBinaryPaths: binaryPaths)

    let serializingProgressNotifier = ProgressNotifier(name: SerializingXcodeProject,
                                                       maxValue: 1,
                                                       indeterminate: true)
    let serializer = OpenStepSerializer(rootObject: projectInfo.project,
                                        gidGenerator: ConcreteGIDGenerator())

    let serializingProfileToken = localizedMessageLogger.startProfiling("serializing_project",
                                                                        context: config.projectName)
    guard let serializedXcodeProject = serializer.serialize() else {
      throw ProjectGeneratorError.serializationFailed("OpenStep serialization failed")
    }
    localizedMessageLogger.logProfilingEnd(serializingProfileToken)

    let projectBundleName = config.xcodeProjectFilename
    let projectURL = outputFolderURL.appendingPathComponent(projectBundleName)
    if !createDirectory(projectURL) {
      throw ProjectGeneratorError.serializationFailed("Project directory creation failed")
    }

    let pbxproj = projectURL.appendingPathComponent("project.pbxproj")
    try writeDataHandler(pbxproj, serializedXcodeProject)
    serializingProgressNotifier.incrementValue()

    try installWorkspaceSettings(projectURL)
    try installXcodeSchemesForProjectInfo(projectInfo,
                                          projectURL: projectURL,
                                          projectBundleName: projectBundleName,
                                          customLLDBInitFile: self.customLLDBInitFile)
    installTulsiScriptsForProjectInfo(projectInfo, projectURL: projectURL)
    installGeneratorConfig(projectURL)
    installGeneratedProjectResources(projectURL)
    installStubExtensionPlistFiles(projectURL,
                                   rules: projectInfo.buildRuleEntries.filter { $0.pbxTargetType?.isiOSAppExtension ?? false },
                                   plistPaths: plistPaths)
    linkTulsiWorkspace(projectURL)
    createUtilsDirectory(projectURL)
    return projectURL
  }

  

  
  
  private func fetchDefaultSwitchVersion() -> String {
    
    if let defaultSwiftVersion = cachedDefaultSwiftVersion {
      return defaultSwiftVersion
    }

    let semaphore = DispatchSemaphore(value: 0)
    var completionInfo: ProcessRunner.CompletionInfo?
    let process = TulsiProcessRunner.createProcess("/usr/bin/xcrun",
                                                   arguments: ["swift", "--version"],
                                                   messageLogger: self.localizedMessageLogger,
                                                   loggingIdentifier: "extract_default_swift_version") {
                                                    processCompletionInfo in
      defer { semaphore.signal() }

      completionInfo = processCompletionInfo
    }
    process.launch()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)

    guard let info = completionInfo else {
      self.localizedMessageLogger.warning("ExtractingDefaultSwiftVersionFailed",
                                          comment: "Default version in %1$@, additional error context in %2$@.",
                                          values: XcodeProjectGenerator.DefaultSwiftVersion,
                                          "Internal error, unable to find process information")
      cachedDefaultSwiftVersion = XcodeProjectGenerator.DefaultSwiftVersion
      return XcodeProjectGenerator.DefaultSwiftVersion
    }

    guard info.terminationStatus == 0,
      let stdout = NSString(data: info.stdout, encoding: String.Encoding.utf8.rawValue) else {
        let stderr = NSString(data: info.stderr, encoding: String.Encoding.utf8.rawValue) ?? "<no stderr>"
        self.localizedMessageLogger.warning("ExtractingDefaultSwiftVersionFailed",
                                            comment: "Default version in %1$@, additional error context in %2$@.",
                                            values: XcodeProjectGenerator.DefaultSwiftVersion,
                                            "xcrun swift --version returned exitcode \(info.terminationStatus) with stderr: \(stderr)")
        cachedDefaultSwiftVersion = XcodeProjectGenerator.DefaultSwiftVersion
        return XcodeProjectGenerator.DefaultSwiftVersion
    }
    
    
    
    
    
    let pattern = "^Apple\\sSwift\\sversion\\s([0-9]+\\.?[0-9]?)"
    guard let regExpr = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
      self.localizedMessageLogger.warning("ExtractingDefaultSwiftVersionFailed",
                                          comment: "Default version in %1$@, additional error context in %2$@.",
                                          values: XcodeProjectGenerator.DefaultSwiftVersion,
                                          "Internal error, unable to create regular expression")
      cachedDefaultSwiftVersion = XcodeProjectGenerator.DefaultSwiftVersion
      return XcodeProjectGenerator.DefaultSwiftVersion
    }
    guard let match = regExpr.firstMatch(in: stdout as String,
                                         range: NSMakeRange(0, stdout.length)) else {
      self.localizedMessageLogger.warning("ExtractingDefaultSwiftVersionFailed",
                                          comment: "Default version in %1$@, additional error context in %2$@.",
                                          values: XcodeProjectGenerator.DefaultSwiftVersion,
                                          "Unable to parse version from xcrun output. Output: \(stdout)")
      cachedDefaultSwiftVersion = XcodeProjectGenerator.DefaultSwiftVersion
      return XcodeProjectGenerator.DefaultSwiftVersion
    }
    cachedDefaultSwiftVersion = stdout.substring(with: match.range(at: 1))
    return stdout.substring(with: match.range(at: 1))
  }

  
  private struct GeneratedProjectInfo {
    
    let project: PBXProject

    
    
    let buildRuleEntries: Set<RuleEntry>

    
    let testSuiteRuleEntries: [BuildLabel: RuleEntry]

    
    let indexerTargets: [String: PBXTarget]

    
    let topLevelBuildTargetsByLabel: [BuildLabel: PBXNativeTarget]

    
    
    let ignoredTestTargets: Set<BuildLabel>
  }

  
  
  private func validateXcodeProjectPath(_ outputPath: URL) throws {
    for (invalidPath, reason) in invalidXcodeProjectPathsWithReasons {
      if outputPath.absoluteString.lowercased().range(of: invalidPath.lowercased()) != nil {
        throw ProjectGeneratorError.invalidXcodeProjectPath(path: outputPath.path, reason: reason +
            " (\"\(invalidPath)\")")
      }
    }

    let usingProjectLldbinit = self.config.options[.DisableCustomLLDBInit].commonValueAsBool != true
    let projectPathHasWhiteSpace =
      outputPath.path.rangeOfCharacter(from: NSCharacterSet.whitespaces) != nil
    
    
    
    if usingProjectLldbinit, projectPathHasWhiteSpace {
      throw ProjectGeneratorError.invalidXcodeProjectPath(
        path: outputPath.path,
        reason: "a path that has white space which will break debugging. Select a new "
          + "destination without whitespace OR enable the 'Disable project-level lldbinit' setting "
          + "in the Shared options tab of your Tulsi project and regenerate with the chosen path"
      )
    }
  }

  
  
  private func validateConfigReferences(_ ruleEntryMap: RuleEntryMap) throws {
    let unresolvedLabels = config.buildTargetLabels.filter {
      !ruleEntryMap.hasAnyRuleEntry(withBuildLabel: $0)
    }
    if !unresolvedLabels.isEmpty {
      throw ProjectGeneratorError.labelResolutionFailed(Set<BuildLabel>(unresolvedLabels))
    }

    var bundleEntriesByMinIos = [String: [RuleEntry]]()

    
    
    for entry in ruleEntryMap.allRuleEntries {
      
      guard entry.productType != nil else { continue }

      
      guard entry.label.targetName != "ios_default_host" else { continue }

      
      
      guard let deploymentTarget = entry.deploymentTarget,
        deploymentTarget.platform == .ios else { continue }

      bundleEntriesByMinIos[deploymentTarget.osVersion, default: []].append(entry)
    }

    
    if bundleEntriesByMinIos.count > 1 {
      let platform = PlatformType.ios.userString

      
      let sortedEntries = bundleEntriesByMinIos.enumerated().sorted { (a, b) -> Bool in
        return a.element.value.count > b.element.value.count
      }
      let debugString = sortedEntries.map { (offset, element) in
        let targets = element.value.map { $0.label.value }.joined(separator: ", ")
        return "\(platform) \(element.key) minimum_os_version: target(s) \(targets)"
      }.joined(separator: "\n")

      localizedMessageLogger.warning("MultiMinOSVersions",
                                   comment: "Warning when multiple bundled targets have different minimum OS versions. Platform type in %1$@, context in %2$@.",
                                   context: config.projectName,
                                   values: platform, debugString)
    }
  }

  
  private func buildXcodeProjectWithMainGroup(_ mainGroup: PBXGroup,
                                              stubInfoPlistPaths: StubInfoPlistPaths,
                                              stubBinaryPaths: StubBinaryPaths) throws -> GeneratedProjectInfo {
    let xcodeProject = PBXProject(name: config.projectName, mainGroup: mainGroup)

    if let enabled = config.options[.SuppressSwiftUpdateCheck].commonValueAsBool, enabled {
      xcodeProject.lastSwiftUpdateCheck = "0710"
    }

    let buildScriptPath = "${PROJECT_FILE_PATH}/\(XcodeProjectGenerator.ScriptDirectorySubpath)/\(XcodeProjectGenerator.BuildScript)"
    let cleanScriptPath = "${PROJECT_FILE_PATH}/\(XcodeProjectGenerator.ScriptDirectorySubpath)/\(XcodeProjectGenerator.CleanScript)"

    let generator = pbxTargetGeneratorType.init(bazelPath: config.bazelURL.path,
                                                bazelBinPath: workspaceInfoExtractor.bazelBinPath,
                                                project: xcodeProject,
                                                buildScriptPath: buildScriptPath,
                                                stubInfoPlistPaths: stubInfoPlistPaths,
                                                stubBinaryPaths: stubBinaryPaths,
                                                tulsiVersion: tulsiVersion,
                                                options: config.options,
                                                localizedMessageLogger: localizedMessageLogger,
                                                workspaceRootURL: workspaceRootURL,
                                                suppressCompilerDefines: suppressCompilerDefines)

    if let additionalFilePaths = config.additionalFilePaths {
      generator.generateFileReferencesForFilePaths(additionalFilePaths)
    }

    let ruleEntryMap = try loadRuleEntryMap()
    try validateConfigReferences(ruleEntryMap)

    
    
    var ignoredTests = Set<BuildLabel>()
    var expandedTargetLabels = Set<BuildLabel>()
    var testSuiteRules = [BuildLabel: RuleEntry]()
    func expandTargetLabels<T: Sequence>(_ labels: T, inTestSuite: Bool) where T.Iterator.Element == BuildLabel {
      for label in labels {
        
        
        let ruleEntries = ruleEntryMap.ruleEntries(buildLabel: label)
        for ruleEntry in ruleEntries {
          if ruleEntry.type != "test_suite" {
            
            guard !inTestSuite || ruleEntry.pbxTargetType != nil else {
              ignoredTests.insert(label)
              continue
            }
            
            
            expandedTargetLabels.insert(label)
            expandedTargetLabels.formUnion(ruleEntry.extensions)
            expandedTargetLabels.formUnion(ruleEntry.appClips)

            
            expandTargetLabels(ruleEntry.extensions, inTestSuite: false)
          } else {
            
            testSuiteRules[ruleEntry.label] = ruleEntry
            expandTargetLabels(ruleEntry.testSuiteDependencies, inTestSuite: true)
          }
        }
      }
    }
    expandTargetLabels(config.buildTargetLabels, inTestSuite: false)

    var targetRules = Set<RuleEntry>()
    var hostTargetLabels = [BuildLabel: BuildLabel]()

    func profileAction(_ name: String, action: () throws -> Void) rethrows {
      let profilingToken = localizedMessageLogger.startProfiling(name, context: config.projectName)
      try action()
      localizedMessageLogger.logProfilingEnd(profilingToken)
    }

    profileAction("gathering_sources_for_indexers") {
      
      
      
      var processedEntries = [RuleEntry: (NSOrderedSet)]()
      let progressNotifier = ProgressNotifier(name: GatheringIndexerSources,
                                              maxValue: expandedTargetLabels.count)
      for label in expandedTargetLabels {
        progressNotifier.incrementValue()
        let ruleEntries = ruleEntryMap.ruleEntries(buildLabel: label)
        guard !ruleEntries.isEmpty else {
          localizedMessageLogger.error("UnknownTargetRule",
                                       comment: "Failure to look up a Bazel target that was expected to be present. The target label is %1$@",
                                       context: config.projectName,
                                       values: label.value)
          continue
        }
        for ruleEntry in ruleEntries {
          targetRules.insert(ruleEntry)
          for hostTargetLabel in ruleEntry.linkedTargetLabels {
            hostTargetLabels[hostTargetLabel] = ruleEntry.label
          }
          autoreleasepool {
            generator.registerRuleEntryForIndexer(ruleEntry,
                                                  ruleEntryMap: ruleEntryMap,
                                                  pathFilters: config.pathFilters,
                                                  processedEntries: &processedEntries)
          }
        }
      }
    }
    var indexerTargets = [String: PBXTarget]()
    profileAction("generating_indexers") {
      let progressNotifier = ProgressNotifier(name: GeneratingIndexerTargets,
                                              maxValue: 1,
                                              indeterminate: true)
      indexerTargets = generator.generateIndexerTargets()
      progressNotifier.incrementValue()
    }

    if let includeSkylarkSources = config.options[.IncludeBuildSources].commonValueAsBool,
       includeSkylarkSources {
      profileAction("adding_buildfiles") {
        let buildfiles = workspaceInfoExtractor.extractBuildfiles(expandedTargetLabels)
        let paths = buildfiles.map() { $0.asFileName! }
        generator.generateFileReferencesForFilePaths(paths, pathFilters: config.pathFilters)
      }
    }

    
    for (hostLabel, _) in hostTargetLabels {
      if config.buildTargetLabels.contains(hostLabel) { continue }
      guard let recoveredHostRuleEntry = ruleEntryMap.anyRuleEntry(withBuildLabel: hostLabel) else {
        
        
        continue
      }
      
      targetRules.insert(recoveredHostRuleEntry)
    }

    let workingDirectory = pbxTargetGeneratorType.workingDirectoryForPBXGroup(mainGroup)
    profileAction("generating_clean_target") {
      let bazelSettingsProvider = workspaceInfoExtractor.bazelSettingsProvider
      let startupOptions = bazelSettingsProvider.universalFlags.startup
      generator.generateBazelCleanTarget(cleanScriptPath, workingDirectory: workingDirectory,
                                         startupOptions: startupOptions)
    }
    let useBazelCacheReader = config.options[.UseBazelCacheReader].commonValueAsBool == true
    profileAction("generating_top_level_build_configs") {
      var buildSettings = [String: String]()
      if let sdkroot = XcodeProjectGenerator.projectSDKROOT(targetRules) {
        buildSettings = ["SDKROOT": sdkroot]
      }
      
      for entry in targetRules {
        if let swiftVersion = entry.attributes[.swift_language_version] as? String {
          buildSettings["SWIFT_VERSION"] = swiftVersion
        } else if entry.attributes[.has_swift_dependency] as? Bool ?? false {
          buildSettings["SWIFT_VERSION"] = fetchDefaultSwitchVersion()
        }
        if let swiftToolchain = entry.attributes[.swift_toolchain] as? String {
          buildSettings["TOOLCHAINS"] = swiftToolchain
        }
      }

      if let genRunfiles = config.options[.GenerateRunfiles].commonValueAsBool, genRunfiles {
        buildSettings["GENERATE_RUNFILES"] = "YES"
      }

      if let customLLDBInitFile = self.customLLDBInitFile {
        
        buildSettings["TULSI_LLDBINIT_FILE"] = customLLDBInitFile
      }

      if useBazelCacheReader {
        buildSettings["TULSI_USE_BAZEL_CACHE_READER"] = "YES"
      }

      buildSettings["TULSI_PROJECT"] = config.projectName
      generator.generateTopLevelBuildConfigurations(buildSettings)
    }
    var targetsByLabel = [BuildLabel: PBXNativeTarget]()
    try profileAction("generating_build_targets") {
      let useFilters = config.options[.PathFiltersApplyToTestSources].commonValueAsBool ?? true
      let pathFilters = useFilters ? config.pathFilters : nil
      targetsByLabel = try generator.generateBuildTargetsForRuleEntries(targetRules,
                                                       ruleEntryMap: ruleEntryMap,
                                                        pathFilters: pathFilters)
    }

    let referencePatcher = BazelXcodeProjectPatcher(fileManager: fileManager)
    profileAction("patching_bazel_relative_references") {
      referencePatcher.patchBazelRelativeReferences(xcodeProject, workspaceRootURL)
    }
    profileAction("patching_external_repository_references") {
      referencePatcher.patchExternalRepositoryReferences(xcodeProject)
    }
    profileAction("updating_dbgshellcommands") {
      do {
        try updateShellCommands(useBazelCacheReader: useBazelCacheReader)
      } catch {
        self.localizedMessageLogger.warning("UpdatingDBGShellCommandsFailed",
                                            comment: LocalizedMessageLogger.bugWorthyComment("Failed to update the script to find cached dSYM bundles via DBGShellCommands."),
                                            context: self.config.projectName,
                                            values: "\(error)")
      }
    }
    profileAction("cleaning_cached_dsym_paths") {
      cleanCachedDsymPaths()
    }
    
    if self.customLLDBInitFile == nil {
      profileAction("bootstrapping_lldbinit") {
        bootstrapLLDBInit()
      }
    }

    if !suppressModuleCachePrunerInstallation {
      do {
        _ = try installAuxiliaryExecutable(XcodeProjectGenerator.ModuleCachePrunerUtil)
      } catch {
        self.localizedMessageLogger.warning("InstallModuleCachePrunerFailed",
                                            comment: LocalizedMessageLogger.bugWorthyComment("Failed to install the module cache pruner executable."),
                                            context: self.config.projectName,
                                            values: "\(error)")
      }
    }

    return GeneratedProjectInfo(project: xcodeProject,
                                buildRuleEntries: targetRules,
                                testSuiteRuleEntries: testSuiteRules,
                                indexerTargets: indexerTargets,
                                topLevelBuildTargetsByLabel: targetsByLabel,
                                ignoredTestTargets: ignoredTests)
  }

  private func installWorkspaceSettings(_ projectURL: URL) throws {
    func writeWorkspaceSettings(_ workspaceSettings: [String: Any],
                                toDirectoryAtURL directoryURL: URL,
                                replaceIfExists: Bool = false) throws {

      let workspaceSettingsURL = directoryURL.appendingPathComponent("WorkspaceSettings.xcsettings")
      if (!replaceIfExists && fileManager.fileExists(atPath: workspaceSettingsURL.path)) ||
          !createDirectory(directoryURL) {
        return
      }

      let data = try PropertyListSerialization.data(fromPropertyList: workspaceSettings,
                                                                      format: .xml,
                                                                      options: 0)
      try writeDataHandler(workspaceSettingsURL, data)
    }


    let workspaceSharedDataURL = projectURL.appendingPathComponent("project.xcworkspace/xcshareddata")
    var sharedWorkspaceSettings: [String: Any] = [
      "IDEWorkspaceSharedSettings_AutocreateContextsIfNeeded": false as AnyObject,
    ]
    if config.options.useLegacyBuildSystem {
      sharedWorkspaceSettings["BuildSystemType"] = "Original"
      
      sharedWorkspaceSettings["DisableBuildSystemDeprecationWarning"] = true as AnyObject
      
      sharedWorkspaceSettings["DisableBuildSystemDeprecationDiagnostic"] = true as AnyObject
    }
    try writeWorkspaceSettings(sharedWorkspaceSettings,
                               toDirectoryAtURL: workspaceSharedDataURL,
                               replaceIfExists: true)

    let workspaceUserDataURL = projectURL.appendingPathComponent("project.xcworkspace/xcuserdata/\(usernameFetcher()).xcuserdatad")
    let perUserWorkspaceSettings: [String: Any] = [
        "LiveSourceIssuesEnabled": true,
        "IssueFilterStyle": "ShowAll",
    ]
    try writeWorkspaceSettings(perUserWorkspaceSettings, toDirectoryAtURL: workspaceUserDataURL)
  }

  private func loadRuleEntryMap() throws -> RuleEntryMap {
    do {
      let features = BazelBuildSettingsFeatures.enabledFeatures(options: config.options)
      return try workspaceInfoExtractor.ruleEntriesForLabels(config.buildTargetLabels,
                                                             startupOptions: config.options[.BazelBuildStartupOptionsDebug],
                                                             extraStartupOptions: config.options[.ProjectGenerationBazelStartupOptions],
                                                             buildOptions: config.options[.BazelBuildOptionsDebug],
                                                             compilationModeOption: config.options[.ProjectGenerationCompilationMode],
                                                             platformConfigOption: config.options[.ProjectGenerationPlatformConfiguration],
                                                             prioritizeSwiftOption: config.options[.ProjectPrioritizesSwift],
                                                             use64BitWatchSimulatorOption: config.options[.Use64BitWatchSimulator],
                                                             features: features)
    } catch BazelWorkspaceInfoExtractorError.aspectExtractorFailed(let info) {
      throw ProjectGeneratorError.labelAspectFailure(info)
    }
  }

  
  
  
  private func linkTulsiWorkspace(_ projectURL: URL) {
    
    guard !self.redactSymlinksToBazelOutput else { return }

    func createLink(from: String, to: String) {
      let from = projectURL.appendingPathComponent(from, isDirectory: false).path

      
      if let attributes = try? self.fileManager.attributesOfItem(atPath: from) {
        
        if attributes[FileAttributeKey.type] as? FileAttributeType == FileAttributeType.typeSymbolicLink {
          do {
            let oldDestination = try self.fileManager.destinationOfSymbolicLink(atPath: from)
            guard oldDestination != to else { return }
          } catch {
            self.localizedMessageLogger.warning("UpdatingTulsiSymlinksFailed",
                                                comment: "Warning shown when failing to update the tulsi symlinks into the Bazel output files. symlink path is in %1$@, symlink destination is in %2$@, additional error context in %3$@.",
                                                context: self.config.projectName,
                                                values: from, to, "Unable to read old symlink. Was it modified?")
            return
          }
        }

        
        do {
          try self.fileManager.removeItem(atPath: from)
        } catch {
          self.localizedMessageLogger.warning("UpdatingTulsiSymlinksFailed",
                                              comment: "Warning shown when failing to update the tulsi symlinks into the Bazel output files. symlink path is in %1$@, symlink destination is in %2$@, additional error context in %3$@.",
                                              context: self.config.projectName,
                                              values: from, to, "Unable to remove the old symlink. Trying removing it and try again.")
          return
        }
      }

      
      do {
        try self.fileManager.createSymbolicLink(atPath: from, withDestinationPath: to)
      } catch {
        self.localizedMessageLogger.warning("UpdatingTulsiSymlinksFailed",
                                            comment: "Warning shown when failing to update the tulsi symlinks into the Bazel output files. symlink path is in %1$@, symlink destination is in %2$@, additional error context in %3$@.",
                                            context: self.config.projectName,
                                            values: from, to, "Creating symlink failed. Is it already present?")
      }

    }

    createLink(from: PBXTargetGenerator.TulsiExecutionRootSymlinkPath,
               to: self.workspaceInfoExtractor.bazelExecutionRoot)
    createLink(from: PBXTargetGenerator.TulsiExecutionRootSymlinkLegacyPath,
               to: self.workspaceInfoExtractor.bazelExecutionRoot)
    createLink(from: PBXTargetGenerator.TulsiOutputBaseSymlinkPath,
               to: self.workspaceInfoExtractor.bazelOutputBase)
  }

  
  private func installXcodeSchemesForProjectInfo(_ info: GeneratedProjectInfo,
                                                 projectURL: URL,
                                                 projectBundleName: String,
                                                 customLLDBInitFile: String?) throws {
    let xcschemesURL = projectURL.appendingPathComponent("xcshareddata/xcschemes")
    guard createDirectory(xcschemesURL) else { return }

    let userSchemeSubpath = "xcuserdata/\(usernameFetcher()).xcuserdatad/xcschemes"
    let userSchemesURL = projectURL.appendingPathComponent(userSchemeSubpath)
    guard createDirectory(userSchemesURL) else { return }

    func updateManagementDictionary(
      _ dictionary: inout [String: Any],
      schemeName: String,
      shared: Bool = true,
      visible: Bool = true
    ) {
      guard var schemeUserState = dictionary["SchemeUserState"] as? [String: Any] else {
        return
      }
      let actualizedName = shared ? "\(schemeName)_^#shared#^_" : schemeName
      let schemeDict: [String: Any] = ["isShown": visible]
      schemeUserState[actualizedName] = schemeDict
      dictionary["SchemeUserState"] = schemeUserState
    }

    func targetForLabel(_ label: BuildLabel) -> PBXTarget? {
      if let pbxTarget = info.topLevelBuildTargetsByLabel[label] {
        return pbxTarget
      }
      if let pbxTarget = info.project.targetByName[label.targetName!] {
        return pbxTarget
      } else if let pbxTarget = info.project.targetByName[label.asFullPBXTargetName!] {
        return pbxTarget
      }
      return nil
    }

    func commandlineArguments(for ruleEntry: RuleEntry) -> [String] {
      return config.options[.CommandlineArguments, ruleEntry.label.value]?.components(separatedBy: " ") ?? []
    }

    func environmentVariables(for ruleEntry: RuleEntry) -> [String: String] {
      var environmentVariables: [String: String] = [:]
      config.options[.EnvironmentVariables, ruleEntry.label.value]?.components(separatedBy: .newlines).forEach() { keyValueString in
        let components = keyValueString.components(separatedBy: "=")
        let key = components.first ?? ""
        if !key.isEmpty {
          let value = components[1..<components.count].joined(separator: "=")
          environmentVariables[key] = value
        }
      }
      return environmentVariables
    }

    func preActionScripts(for ruleEntry: RuleEntry) -> [XcodeActionType: String] {
      var preActionScripts: [XcodeActionType: String] = [:]
      preActionScripts[.BuildAction] = config.options[.BuildActionPreActionScript, ruleEntry.label.value] ?? nil
      preActionScripts[.LaunchAction] = config.options[.LaunchActionPreActionScript, ruleEntry.label.value] ?? nil
      preActionScripts[.TestAction] = config.options[.TestActionPreActionScript, ruleEntry.label.value] ?? nil
      return preActionScripts
    }

    func postActionScripts(for ruleEntry: RuleEntry) -> [XcodeActionType: String] {
      var postActionScripts: [XcodeActionType: String] = [:]
      postActionScripts[.BuildAction] = config.options[.BuildActionPostActionScript, ruleEntry.label.value] ?? nil
      postActionScripts[.LaunchAction] = config.options[.LaunchActionPostActionScript, ruleEntry.label.value] ?? nil
      postActionScripts[.TestAction] = config.options[.TestActionPostActionScript, ruleEntry.label.value] ?? nil
      return postActionScripts
    }

    
    
    
    
    var extensionHosts = [BuildLabel: Set<RuleEntry>]()
    for entry in info.buildRuleEntries {
      for extensionLabel in entry.extensions {
        if var entrySet = extensionHosts[extensionLabel] {
          entrySet.insert(entry)
          extensionHosts[extensionLabel] = entrySet
        } else {
          extensionHosts[extensionLabel] = Set([entry])
        }
      }
    }

    var schemeManagementDict = [String: Any]()
    schemeManagementDict["SchemeUserState"] = [String: Any]()
    schemeManagementDict["SuppressBuildableAutocreation"] = [String: Any]()

    let runTestTargetBuildConfigPrefix = pbxTargetGeneratorType.getRunTestTargetBuildConfigPrefix()
    for entry in info.buildRuleEntries {
      
      
      let target: PBXNativeTarget
      if let pbxTarget = targetForLabel(entry.label) as? PBXNativeTarget {
        target = pbxTarget
      } else {
        localizedMessageLogger.warning("XCSchemeGenerationFailed",
                                       comment: "Warning shown when generation of an Xcode scheme failed for build target %1$@",
                                       context: config.projectName,
                                       values: entry.label.value)
        continue
      }

      let targetType = entry.pbxTargetType ?? .Application

      var appExtension: Bool = false
      var extensionType: String? = nil
      var launchStyle: XcodeScheme.LaunchStyle? = .Normal
      var runnableDebuggingMode: XcodeScheme.RunnableDebuggingMode = .Default

      if targetType.isiOSAppExtension {
        appExtension = true
        launchStyle = .AppExtension
        extensionType = entry.extensionType
      } else if targetType.isWatchApp {
        runnableDebuggingMode = .Remote
      } else if targetType.isLibrary {
        launchStyle = nil
      } else if targetType.isTest {
        
        launchStyle = nil
      }

      var schemeEnvVars = environmentVariables(for: entry)
      if let genRunfiles = config.options[.GenerateRunfiles].commonValueAsBool,
         let productType = entry.productType,
          genRunfiles && (productType == .UnitTest || productType == .UIUnitTest) {
        let bazelBinPath = "$(TULSI_WR)/\(workspaceInfoExtractor.bazelBinPath)"
        schemeEnvVars["TEST_SRCDIR"] = "\(bazelBinPath)/$(TULSI_BUILD_PATH)/$(TARGET_NAME).runfiles"
      }

      var extensionHostsForEntry = extensionHosts[entry.label] ?? Set<RuleEntry>()
      
      
      let addHostNameToFilename = extensionHostsForEntry.count > 1

      
      
      repeat {
        var filename = String()
        var additionalBuildTargets = target.buildActionDependencies.map() {
          ($0, projectBundleName, XcodeScheme.makeBuildActionEntryAttributes())
        }

        if !extensionHostsForEntry.isEmpty {
          let host = extensionHostsForEntry.removeFirst()
          guard let hostTarget = targetForLabel(host.label) else {
            localizedMessageLogger.warning("XCSchemeGenerationFailed",
                                           comment: "Warning shown when generation of an Xcode scheme failed for build target %1$@",
                                           details: "Extension host could not be resolved.",
                                           context: config.projectName,
                                           values: entry.label.value)
            continue
          }
          let hostTargetTuple =
            (hostTarget, projectBundleName, XcodeScheme.makeBuildActionEntryAttributes())
          additionalBuildTargets.append(hostTargetTuple)
          if addHostNameToFilename {
            filename += hostTarget.name + "_"
          }
        }

        let scheme = XcodeScheme(target: target,
                                 project: info.project,
                                 projectBundleName: projectBundleName,
                                 testActionBuildConfig: runTestTargetBuildConfigPrefix + "Debug",
                                 profileActionBuildConfig: runTestTargetBuildConfigPrefix + "Release",
                                 appExtension: appExtension,
                                 extensionType: extensionType,
                                 customLLDBInitFile: customLLDBInitFile,
                                 launchStyle: launchStyle,
                                 runnableDebuggingMode: runnableDebuggingMode,
                                 additionalBuildTargets: additionalBuildTargets,
                                 commandlineArguments: commandlineArguments(for: entry),
                                 environmentVariables: schemeEnvVars,
                                 preActionScripts:preActionScripts(for: entry),
                                 postActionScripts:postActionScripts(for: entry),
                                 localizedMessageLogger: localizedMessageLogger)
        let xmlDocument = scheme.toXML()

        filename += target.name + ".xcscheme"
        let url = xcschemesURL.appendingPathComponent(filename)

        let data = xmlDocument.xmlData(options: XMLNode.Options.nodePrettyPrint)
        try writeDataHandler(url, data)
        updateManagementDictionary(&schemeManagementDict, schemeName: filename)
      } while !extensionHostsForEntry.isEmpty
    }

    func extractTestTargets(_ testSuite: RuleEntry) -> (Set<PBXTarget>, PBXTarget?) {
      var suiteHostTarget: PBXTarget? = nil
      var validTests = Set<PBXTarget>()
      for testEntryLabel in testSuite.testSuiteDependencies {
        
        guard !info.ignoredTestTargets.contains(testEntryLabel) else {
          continue
        }

        if let recursiveTestSuite = info.testSuiteRuleEntries[testEntryLabel] {
          let (recursiveTests, recursiveSuiteHostTarget) = extractTestTargets(recursiveTestSuite)
          validTests.formUnion(recursiveTests)
          if suiteHostTarget == nil {
            suiteHostTarget = recursiveSuiteHostTarget
          }
          continue
        }

        guard let testTarget = targetForLabel(testEntryLabel) as? PBXNativeTarget else {
          localizedMessageLogger.warning("TestSuiteUsesUnresolvedTarget",
                                         comment: "Warning shown when a test_suite %1$@ refers to a test label %2$@ that was not resolved and will be ignored",
                                         context: config.projectName,
                                         values: testSuite.label.value, testEntryLabel.value)
          continue
        }

        
        
        if testTarget.productType == .Application {
          localizedMessageLogger.warning("TestSuiteIncludesNonXCTest",
                                         comment: "Warning shown when a non XCTest %1$@ is included in a test suite %2$@ and will be ignored.",
                                         context: config.projectName,
                                         values: testEntryLabel.value, testSuite.label.value)
          continue
        }

        
        let testHostTarget = info.project.linkedHostForTestTarget(testTarget) as? PBXNativeTarget
        if testHostTarget == nil && testTarget.productType != .UnitTest {
          localizedMessageLogger.warning("TestSuiteTestHostResolutionFailed",
                                         comment: "Warning shown when the test host for a test %1$@ inside test suite %2$@ could not be found. The test will be ignored, but this state is unexpected and should be reported.",
                                         context: config.projectName,
                                         values: testEntryLabel.value, testSuite.label.value)
          continue
        }

        if suiteHostTarget == nil {
          suiteHostTarget = testHostTarget
        }

        validTests.insert(testTarget)
      }

      return (validTests, suiteHostTarget)
    }

    func installSchemesForIndexerTargets() throws {
      let indexerTargets = info.indexerTargets.values
      guard !indexerTargets.isEmpty else { return }

      let filename = "_idx_Scheme.xcscheme"
      let url = xcschemesURL.appendingPathComponent(filename)

      let additionalBuildTargets = indexerTargets.map() {
        ($0, projectBundleName, XcodeScheme.makeBuildActionEntryAttributes())
      }

      let scheme = XcodeScheme(target: nil,
                               project: info.project,
                               projectBundleName: projectBundleName,
                               launchStyle: nil,
                               additionalBuildTargets: additionalBuildTargets,
                               preActionScripts: [:],
                               postActionScripts: [:],
                               localizedMessageLogger: localizedMessageLogger)
      let xmlDocument = scheme.toXML()

      let data = xmlDocument.xmlData(options: XMLNode.Options.nodePrettyPrint)
      try writeDataHandler(url, data)
      updateManagementDictionary(&schemeManagementDict, schemeName: filename, visible: false)
    }
    try installSchemesForIndexerTargets()

    func installSchemeForTestSuite(_ suite: RuleEntry, named suiteName: String) throws {
      let (validTests, extractedHostTarget) = extractTestTargets(suite)
      guard !validTests.isEmpty else {
        localizedMessageLogger.warning("TestSuiteHasNoValidTests",
                                       comment: "Warning shown when none of the tests of a test suite %1$@ were able to be resolved.",
                                       context: config.projectName,
                                       values: suite.label.value)
        return
      }

      let filename = suiteName + "_Suite.xcscheme"

      let url = xcschemesURL.appendingPathComponent(filename)
      let scheme = XcodeScheme(target: extractedHostTarget,
                               project: info.project,
                               projectBundleName: projectBundleName,
                               testActionBuildConfig: runTestTargetBuildConfigPrefix + "Debug",
                               profileActionBuildConfig: runTestTargetBuildConfigPrefix + "Release",
                               customLLDBInitFile: customLLDBInitFile,
                               launchStyle: .Normal,
                               explicitTests: Array(validTests),
                               commandlineArguments: commandlineArguments(for: suite),
                               environmentVariables: environmentVariables(for: suite),
                               preActionScripts: preActionScripts(for: suite),
                               postActionScripts:postActionScripts(for: suite),
                               localizedMessageLogger: localizedMessageLogger)
      let xmlDocument = scheme.toXML()


      let data = xmlDocument.xmlData(options: XMLNode.Options.nodePrettyPrint)
      try writeDataHandler(url, data)
      updateManagementDictionary(&schemeManagementDict, schemeName: filename)
    }

    var testSuiteSchemes = [String: [RuleEntry]]()
    for (label, entry) in info.testSuiteRuleEntries {
      let shortName = label.targetName!
      testSuiteSchemes[shortName, default: []].append(entry)
    }
    for testSuites in testSuiteSchemes.values {
      for suite in testSuites {
        let suiteName: String
        if testSuites.count > 1 {
          suiteName = suite.label.asFullPBXTargetName!
        } else {
          suiteName = suite.label.targetName!
        }
        try installSchemeForTestSuite(suite, named: suiteName)
      }
    }

    let schemeManagementURL = userSchemesURL.appendingPathComponent("xcschememanagement.plist")
    guard savePlist(schemeManagementDict, url: schemeManagementURL) else { return }
  }

  
  private func generateBuildSettingsFile(_ buildRuleEntries: Set<RuleEntry>,
                                         _ scriptDirectoryURL: URL) {
    guard !suppressGeneratingBuildSettings else { return }

    let fileURL = scriptDirectoryURL.appendingPathComponent(XcodeProjectGenerator.SettingsScript)

    let bazelSettingsProvider = workspaceInfoExtractor.bazelSettingsProvider
    let bazelExecRoot = workspaceInfoExtractor.bazelExecutionRoot
    let bazelOutputBase = workspaceInfoExtractor.bazelOutputBase
    let features = BazelBuildSettingsFeatures.enabledFeatures(options: config.options)
    let bazelBuildSettings = bazelSettingsProvider.buildSettings(bazel: config.bazelURL.path,
                                                                 bazelExecRoot: bazelExecRoot,
                                                                 bazelOutputBase: bazelOutputBase,
                                                                 options: config.options,
                                                                 features: features,
                                                                 buildRuleEntries: buildRuleEntries)

    let bundle = Bundle(for: type(of: self))

    guard let templateURL = bundle.url(forResource: XcodeProjectGenerator.SettingsScript,
                                       withExtension: "template") else {
      localizedMessageLogger.error("GeneratingBazelBuildSettingsFailed",
                                   comment: "Error message for generating build settings failed. Internal error in %1$@.",
                                   context: config.projectName,
                                   values: "Resource not found: Unable to find the script to template.")
      return
    }

    guard let scriptTemplateData = fileManager.contents(atPath: templateURL.path) else {
      localizedMessageLogger.error("GeneratingBazelBuildSettingsFailed",
                                   comment: "Error message for generating build settings failed. Internal error in %1$@.",
                                   context: config.projectName,
                                   values: "Resource not readable: Unable to read the script to template.")
      return
    }
    guard let scriptTemplate = String.init(data: scriptTemplateData, encoding: .utf8) else {
      localizedMessageLogger.error("GeneratingBazelBuildSettingsFailed",
                                   comment: "Error message for generating build settings failed. Internal error in %1$@.",
                                   context: config.projectName,
                                   values: "Resource parsing failed: Unable to load as utf8.")
      return
    }
    let script = scriptTemplate.replacingOccurrences(of: "# <template>",
                                                     with: "# Generated by Tulsi. DO NOT EDIT.\nBUILD_SETTINGS = \(bazelBuildSettings.toPython(""))")

    var errorInfo: String? = nil
    do {
      try writeDataHandler(fileURL, script.data(using: .utf8)!)
    } catch let e as NSError {
      errorInfo = e.localizedDescription
    } catch {
      errorInfo = "Unexpected exception"
    }
    if let errorInfo = errorInfo {
      localizedMessageLogger.error("GeneratingBazelBuildSettingsFailed",
                                   comment: "Error message for generating build settings failed. Internal error in %1$@.",
                                   context: config.projectName,
                                   values: errorInfo)
      return
    }
  }

  
  private func installAuxiliaryExecutable(_ auxiliaryExecutable: String) throws -> String {
    
    let supportScriptsAbsoluteURL = fileManager.homeDirectoryForCurrentUser.appendingPathComponent(
      XcodeProjectGenerator.SupportScriptsPath, isDirectory: true)

    
    var isDir = ObjCBool(false)
    if !fileManager.fileExists(atPath: supportScriptsAbsoluteURL.path, isDirectory: &isDir) {
      try fileManager.createDirectory(atPath: supportScriptsAbsoluteURL.path,
                                      withIntermediateDirectories: true,
                                      attributes: nil)
    }

    
    let bundle = Bundle(for: type(of: self))
    let sourceURL = bundle.url(forAuxiliaryExecutable: auxiliaryExecutable)!

    
    installFiles([(sourceURL, auxiliaryExecutable)], toDirectory: supportScriptsAbsoluteURL)

    
    let auxiliaryBinaryURL =
        supportScriptsAbsoluteURL.appendingPathComponent(auxiliaryExecutable,
                                                         isDirectory: false)

    return auxiliaryBinaryURL.path
  }

  
  private func removeShellCommandsFromGlobalUserDefaults(shellCommandsBasename: String) {
    
    let dbgDefaults = UserDefaults.standard.persistentDomain(forName: "com.apple.DebugSymbols")

    guard var currentDBGDefaults = dbgDefaults else {
      
      return
    }

    var newShellCommands : [String] = []

    if let currentShellCommands = currentDBGDefaults["DBGShellCommands"] as? [String] {
      
      
      newShellCommands = currentShellCommands.filter { !$0.contains(shellCommandsBasename) }
    } else if let currentShellCommand = currentDBGDefaults["DBGShellCommands"] as? String {
      
      guard currentShellCommand.contains(shellCommandsBasename) else {
        
        return
      }
    }

    
    currentDBGDefaults["DBGShellCommands"] = newShellCommands.isEmpty ? nil : newShellCommands
    UserDefaults.standard.setPersistentDomain(currentDBGDefaults, forName: "com.apple.DebugSymbols")
  }

  
  private func updateGlobalUserDefaultsWithShellCommands(shellCommandsPath: String) {
    guard !suppressModifyingUserDefaults else { return }

    
    var isDir = ObjCBool(false)
    guard fileManager.fileExists(atPath: shellCommandsPath, isDirectory: &isDir) else {
      return
    }

    
    let dbgDefaults = UserDefaults.standard.persistentDomain(forName: "com.apple.DebugSymbols")

    guard var currentDBGDefaults = dbgDefaults else {
      
      
      
      UserDefaults.standard.setPersistentDomain(["DBGShellCommands": [shellCommandsPath],
                                                 "DBGSpotlightPaths": []],
                                                forName: "com.apple.DebugSymbols")
      return
    }

    
    var newShellCommands : [String] = []

    if let currentShellCommands = currentDBGDefaults["DBGShellCommands"] as? [String] {
      
      guard !currentShellCommands.contains(shellCommandsPath) else {
        
        return
      }
      
      newShellCommands = currentShellCommands

    } else if let currentShellCommand = currentDBGDefaults["DBGShellCommands"] as? String {
      
      if currentShellCommand != shellCommandsPath {
        
        newShellCommands.append(currentShellCommand)
      }
    }
    
    newShellCommands.append(shellCommandsPath)

    
    currentDBGDefaults["DBGShellCommands"] = newShellCommands
    UserDefaults.standard.setPersistentDomain(currentDBGDefaults, forName: "com.apple.DebugSymbols")
  }

  
  private func updateShellCommands(useBazelCacheReader: Bool) throws {
    guard !suppressUpdatingShellCommands else { return }

    if useBazelCacheReader {
      
      let shellCommandsAppPath = try installAuxiliaryExecutable(XcodeProjectGenerator.ShellCommandsUtil)

      
      updateGlobalUserDefaultsWithShellCommands(shellCommandsPath: shellCommandsAppPath)
    } else {
      removeShellCommandsFromGlobalUserDefaults(shellCommandsBasename: XcodeProjectGenerator.ShellCommandsUtil)
    }
  }

  private func executePythonProcess(_ scriptFileName: String, onError: @escaping (Int32, String) -> Void) {
    let bundle = Bundle(for: type(of: self))
    let cleanSymbolsSourceURL = bundle.url(forResource: scriptFileName, withExtension: "py")!

    let process = ProcessRunner.createProcess(cleanSymbolsSourceURL.path,
                                              arguments: [String]()) {
      completionInfo in
      if completionInfo.terminationStatus != 0 {
        if let stderr = NSString(data: completionInfo.stderr,
                                 encoding: String.Encoding.utf8.rawValue) {
          guard !stderr.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
          }
          onError(completionInfo.terminationStatus, stderr as String)
        }
      }
    }
    process.launch()
  }

  private func cleanCachedDsymPaths() {
    
    self.executePythonProcess(XcodeProjectGenerator.ShellCommandsCleanScript) { (returncode, stderr) in
      self.localizedMessageLogger.warning("CleanCachedDsymsFailed",
                                          comment: LocalizedMessageLogger.bugWorthyComment("Failed to clean cached references to existing dSYM bundles."),
                                          context: self.config.projectName,
                                          values: returncode, stderr)
    }
  }

  private func createUtilsDirectory(_ projectURL: URL) {
    let scriptDirectoryURL = projectURL.appendingPathComponent(
      XcodeProjectGenerator.UtilDirectorySubpath,
      isDirectory: true)
    _ = createDirectory(scriptDirectoryURL)
  }

  private func bootstrapLLDBInit() {
    
    
    
    self.executePythonProcess(XcodeProjectGenerator.LLDBInitBootstrapScript) { (returncode, stderr) in
      self.localizedMessageLogger.warning("BootstrapLLDBInitFailed",
                                          comment: LocalizedMessageLogger.bugWorthyComment("Failed to bootstrap LLDBInit for debug symbol remapping."),
                                          context: self.config.projectName,
                                          values: returncode, stderr)
    }
  }

  private func installTulsiScriptsForProjectInfo(_ projectInfo: GeneratedProjectInfo,
                                                 projectURL: URL) {
    let scriptDirectoryURL = projectURL.appendingPathComponent(XcodeProjectGenerator.ScriptDirectorySubpath,
                                                                    isDirectory: true)
    if createDirectory(scriptDirectoryURL) {
      let profilingToken = localizedMessageLogger.startProfiling("installing_scripts",
                                                                 context: config.projectName)
      let progressNotifier = ProgressNotifier(name: InstallingScripts, maxValue: 1)
      defer { progressNotifier.incrementValue() }
      localizedMessageLogger.infoMessage("Installing scripts")
      installFiles([(resourceURLs.buildScript, XcodeProjectGenerator.BuildScript),
                    (resourceURLs.cleanScript, XcodeProjectGenerator.CleanScript),
                   ],
                   toDirectory: scriptDirectoryURL)
      installFiles([
        (resourceURLs.stubClang, XcodeProjectGenerator.StubClang),
        (resourceURLs.stubSwiftc, XcodeProjectGenerator.StubSwiftc),
        (resourceURLs.stubLd, XcodeProjectGenerator.StubLd),
      ], toDirectory: scriptDirectoryURL)
      installFiles(resourceURLs.extraBuildScripts.map { ($0, $0.lastPathComponent) },
                   toDirectory: scriptDirectoryURL)
      generateBuildSettingsFile(projectInfo.buildRuleEntries, scriptDirectoryURL)

      localizedMessageLogger.logProfilingEnd(profilingToken)
    }
  }

  private func installGeneratorConfig(_ projectURL: URL) {
    let configDirectoryURL = projectURL.appendingPathComponent(XcodeProjectGenerator.ConfigDirectorySubpath,
                                                                    isDirectory: true)
    guard createDirectory(configDirectoryURL, failSilently: true) else { return }
    let profilingToken = localizedMessageLogger.startProfiling("installing_generator_config",
                                                               context: config.projectName)
    let progressNotifier = ProgressNotifier(name: InstallingGeneratorConfig, maxValue: 1)
    defer { progressNotifier.incrementValue() }
    localizedMessageLogger.infoMessage("Installing generator config")

    let configURL = configDirectoryURL.appendingPathComponent(config.defaultFilename)
    var errorInfo: String? = nil
    do {
      let data = try config.save()
      try writeDataHandler(configURL, data as Data)
    } catch let e as NSError {
      errorInfo = e.localizedDescription
    } catch {
      errorInfo = "Unexpected exception"
    }
    if let errorInfo = errorInfo {
      localizedMessageLogger.syslogMessage("Generator config serialization failed. \(errorInfo)",
                                           context: config.projectName)
      return
    }

    let perUserConfigURL = configDirectoryURL.appendingPathComponent(TulsiGeneratorConfig.perUserFilename)
    errorInfo = nil
    do {
      if let data = try config.savePerUserSettings() {
        try writeDataHandler(perUserConfigURL, data as Data)
      }
    } catch let e as NSError {
      errorInfo = e.localizedDescription
    } catch {
      errorInfo = "Unexpected exception"
    }
    if let errorInfo = errorInfo {
      localizedMessageLogger.syslogMessage("Generator per-user config serialization failed. \(errorInfo)",
                                           context: config.projectName)
      return
    }
    localizedMessageLogger.logProfilingEnd(profilingToken)
  }

  private func installGeneratedProjectResources(_ projectURL: URL) {

    let targetDirectoryURL = projectURL.appendingPathComponent(XcodeProjectGenerator.ProjectResourcesDirectorySubpath,
                                                                    isDirectory: true)
    guard createDirectory(targetDirectoryURL) else { return }
    let profilingToken = localizedMessageLogger.startProfiling("installing_project_resources",
                                                               context: config.projectName)
    localizedMessageLogger.infoMessage("Installing project resources")

    installFiles([(resourceURLs.iOSUIRunnerEntitlements, XcodeProjectGenerator.IOSUIRunnerEntitlements),
                  (resourceURLs.macOSUIRunnerEntitlements, XcodeProjectGenerator.MacOSUIRunnerEntitlements),
                  (resourceURLs.stubInfoPlist, XcodeProjectGenerator.StubInfoPlistFilename),
                  (resourceURLs.stubWatchOS2InfoPlist, XcodeProjectGenerator.StubWatchOS2InfoPlistFilename),
                  (resourceURLs.stubWatchOS2AppExInfoPlist, XcodeProjectGenerator.StubWatchOS2AppExInfoPlistFilename),
                 ],
                 toDirectory: targetDirectoryURL)


    localizedMessageLogger.logProfilingEnd(profilingToken)
  }

  private func installStubExtensionPlistFiles(_ projectURL: URL, rules: [RuleEntry], plistPaths: StubInfoPlistPaths) {
    let targetDirectoryURL = projectURL.appendingPathComponent(XcodeProjectGenerator.ProjectResourcesDirectorySubpath,
                                                               isDirectory: true)
    guard createDirectory(targetDirectoryURL) else { return }
    let profilingToken = localizedMessageLogger.startProfiling("installing_plist_files",
                                                               context: config.projectName)
    localizedMessageLogger.infoMessage("Installing plist files")

    let templatePath = resourceURLs.stubIOSAppExInfoPlistTemplate.path
    guard let plistTemplateData = fileManager.contents(atPath: templatePath) else {
      localizedMessageLogger.error("PlistTemplateNotFound",
                                   comment: LocalizedMessageLogger.bugWorthyComment("Failed to load a plist template"),
                                   context: config.projectName,
                                   values: templatePath)
      return
    }

    let plistTemplate: NSDictionary
    do {
      plistTemplate = try PropertyListSerialization.propertyList(from: plistTemplateData,
                                                                 options: PropertyListSerialization.ReadOptions.mutableContainers,
                                                                 format: nil) as! NSDictionary
    } catch let e {
      localizedMessageLogger.error("PlistDeserializationFailed",
                                   comment: LocalizedMessageLogger.bugWorthyComment("Failed to deserialize a plist template"),
                                   context: config.projectName,
                                   values: resourceURLs.stubIOSAppExInfoPlistTemplate.path, e.localizedDescription)
      return
    }

    for entry in rules {
      plistTemplate.setValue(entry.extensionType, forKeyPath: "NSExtension.NSExtensionPointIdentifier")

      let plistName = plistPaths.plistFilename(forRuleEntry: entry)
      let targetURL = URL(string: plistName, relativeTo: targetDirectoryURL)!

      guard savePlist(plistTemplate, url: targetURL) else {
        return
      }
    }


    localizedMessageLogger.logProfilingEnd(profilingToken)
  }

  private func savePlist(_ plist: Any, url: URL) -> Bool {
    let data: Data
    do {
      data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    } catch let e {
      let comment = LocalizedMessageLogger.bugWorthyComment("Failed to serialize a plist")
      localizedMessageLogger.error("SerializingPlistFailed",
                                   comment: comment,
                                   context: config.projectName,
                                   values: e.localizedDescription)
      return false
    }

    guard fileManager.createFile(atPath: url.path, contents: data, attributes: nil) else {
      let comment = LocalizedMessageLogger.bugWorthyComment("Failed to write a plist")
      localizedMessageLogger.error("WritingPlistFailed",
                                   comment: comment,
                                   context: config.projectName,
                                   values: url.path)
      return false
    }
    return true
  }

  private func createDirectory(_ resourceDirectoryURL: URL, failSilently: Bool = false) -> Bool {
    do {
      try fileManager.createDirectory(at: resourceDirectoryURL,
                                           withIntermediateDirectories: true,
                                           attributes: nil)
    } catch let e as NSError {
      if !failSilently {
        localizedMessageLogger.error("DirectoryCreationFailed",
                                     comment: "Failed to create an important directory. The resulting project will most likely be broken. A bug should be reported.",
                                     context: config.projectName,
                                     values: resourceDirectoryURL as NSURL, e.localizedDescription)
      }
      return false
    }
    return true
  }

  private func installFiles(_ files: [(sourceURL: URL, filename: String)],
                            toDirectory directory: URL, failSilently: Bool = false) {
    for (sourceURL, filename) in files {
      let targetURL = directory.appendingPathComponent(filename, isDirectory: false)

      let errorInfo: String?
      do {
        
        if fileManager.fileExists(atPath: targetURL.path) {
          guard !fileManager.contentsEqual(atPath: sourceURL.path, andPath: targetURL.path) else {
            continue
          }
          print("Overwriting \(targetURL.path) as its contents changed.")
          try fileManager.removeItem(at: targetURL)
        }
        try fileManager.copyItem(at: sourceURL, to: targetURL)
        
        try fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: targetURL.path)
        errorInfo = nil
      } catch let e as NSError {
        errorInfo = e.localizedDescription
      } catch {
        errorInfo = "Unexpected exception"
      }
      if !failSilently, let errorInfo = errorInfo {
        let targetURLString = targetURL.absoluteString
        localizedMessageLogger.error("CopyingResourceFailed",
                                     comment: "Failed to copy an important file resource, the resulting project will most likely be broken. A bug should be reported.",
                                     context: config.projectName,
                                     values: sourceURL as NSURL, targetURLString, errorInfo)
      }
    }
  }


  func logPendingMessages() {
    if workspaceInfoExtractor.hasQueuedInfoMessages() {
      localizedMessageLogger.debugMessage("Printing Bazel logs that could contain the error.")
      workspaceInfoExtractor.logQueuedInfoMessages()
    }
  }


  
  private class PathTrie {
    private var root = PathNode(pathElement: "")

    func insert(_ path: URL) {
      let components = path.pathComponents
      guard !components.isEmpty else {
        return
      }
      root.addPath(components)
    }

    func leafPaths() -> [URL] {
      var ret = [URL]()
      for n in root.children.values {
        for path in n.leafPaths() {
          guard let url = NSURL.fileURL(withPathComponents: path) else {
            continue
          }
          ret.append(url as URL)
        }
      }
      return ret
    }

    private class PathNode {
      let value: String
      var children = [String: PathNode]()

      init(pathElement: String) {
        self.value = pathElement
      }

      func addPath<T: Collection>(_ pathComponents: T)
                  where T.Iterator.Element == String {
        guard let firstComponent = pathComponents.first else {
          return
        }

        let node: PathNode
        if let existingNode = children[firstComponent] {
          node = existingNode
        } else {
          node = PathNode(pathElement: firstComponent)
          children[firstComponent] = node
        }
        let remaining = pathComponents.dropFirst()
        if !remaining.isEmpty {
          node.addPath(remaining)
        }
      }

      func leafPaths() -> [[String]] {
        if children.isEmpty {
          return [[value]]
        }
        var ret = [[String]]()
        for n in children.values {
          for childPath in n.leafPaths() {
            var subpath = [value]
            subpath.append(contentsOf: childPath)
            ret.append(subpath)
          }
        }
        return ret
      }
    }
  }
}
