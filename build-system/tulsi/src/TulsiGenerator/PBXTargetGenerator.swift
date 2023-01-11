

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



struct StubInfoPlistPaths {
  let resourcesDirectory: String
  let defaultStub: String
  let watchOSStub: String
  let watchOSAppExStub: String

  func stubPlist(_ entry: RuleEntry) -> String {

    switch entry.pbxTargetType! {
    case .Watch1App, .Watch2App:
      return watchOSStub

    case .Watch1Extension, .Watch2Extension:
      return watchOSAppExStub

    case .MessagesExtension:
      fallthrough
    case .MessagesStickerPackExtension:
      fallthrough
    case .AppExtension:
      return stubProjectPath(forRuleEntry: entry)

    default:
      return defaultStub
    }
  }

  func plistFilename(forRuleEntry ruleEntry: RuleEntry) -> String {
    return "Stub_\(ruleEntry.label.asFullPBXTargetName!).plist"
  }

  func stubProjectPath(forRuleEntry ruleEntry: RuleEntry) -> String {
    let fileName = plistFilename(forRuleEntry: ruleEntry)
    return "\(resourcesDirectory)/\(fileName)"
  }
}



struct StubBinaryPaths {
  let clang: String
  let swiftc: String
  let ld: String
}


protocol PBXTargetGeneratorProtocol: AnyObject {
  static func getRunTestTargetBuildConfigPrefix() -> String

  static func workingDirectoryForPBXGroup(_ group: PBXGroup) -> String

  
  static func mainGroupForOutputFolder(_ outputFolderURL: URL, workspaceRootURL: URL) -> PBXGroup

  init(bazelPath: String,
       bazelBinPath: String,
       project: PBXProject,
       buildScriptPath: String,
       stubInfoPlistPaths: StubInfoPlistPaths,
       stubBinaryPaths: StubBinaryPaths,
       tulsiVersion: String,
       options: TulsiOptionSet,
       localizedMessageLogger: LocalizedMessageLogger,
       workspaceRootURL: URL,
       suppressCompilerDefines: Bool)

  
  
  
  func generateFileReferencesForFilePaths(_ paths: [String], pathFilters: Set<String>?)

  
  
  
  
  func registerRuleEntryForIndexer(_ ruleEntry: RuleEntry,
                                   ruleEntryMap: RuleEntryMap,
                                   pathFilters: Set<String>,
                                   processedEntries: inout [RuleEntry: (NSOrderedSet)])

  
  
  
  
  func generateIndexerTargets() -> [String: PBXTarget]

  
  
  
  func generateBazelCleanTarget(_ scriptPath: String, workingDirectory: String,
                                startupOptions: [String])

  
  func generateTopLevelBuildConfigurations(_ buildSettingOverrides: [String: String])

  
  
  
  
  
  
  
  
  func generateBuildTargetsForRuleEntries(
    _ entries: Set<RuleEntry>,
    ruleEntryMap: RuleEntryMap,
    pathFilters: Set<String>?
  ) throws -> [BuildLabel: PBXNativeTarget]
}

extension PBXTargetGeneratorProtocol {
  func generateFileReferencesForFilePaths(_ paths: [String]) {
    generateFileReferencesForFilePaths(paths, pathFilters: nil)
  }
}



final class PBXTargetGenerator: PBXTargetGeneratorProtocol {

  enum ProjectSerializationError: Error {
    case buildFileIsNotContainedByProjectRoot
    case generalFailure(String)
    case unsupportedTargetType(String, String)
  }

  
  
  static let buildConfigNames = ["Debug", "Release"]

  
  
  static let testRunnerEnabledBuildConfigNames = ["Debug", "Release"].map({
    (runTestTargetBuildConfigPrefix + $0, $0)
  })

  
  
  
  
  
  
  static let runTestTargetBuildConfigPrefix = "__TulsiTestRunner_"
  static func getRunTestTargetBuildConfigPrefix() -> String {
    return runTestTargetBuildConfigPrefix
  }

  
  
  static let IndexerTargetPrefix = "_idx_"

  
  
  static let MaxIndexerNameLength = 180

  
  
  private static let watchAppExtensionTargetPrefix = "_tulsi_appex_"

  
  
  static let BazelCleanTarget = "_bazel_clean_"

  
  static let WorkspaceRootVarName = "TULSI_WR"

  
  static let TulsiExecutionRootSymlinkPath = ".tulsi/tulsi-execution-root"
  
  
  static let TulsiExecutionRootSymlinkLegacyPath = ".tulsi/tulsi-workspace"


  
  static let BazelExecutionRootSymlinkVarName = "TULSI_EXECUTION_ROOT"
  
  
  static let BazelExecutionRootSymlinkLegacyVarName = "TULSI_BWRS"

  
  static let TulsiOutputBaseSymlinkPath = ".tulsi/tulsi-output-base"

  
  static let BazelOutputBaseSymlinkVarName = "TULSI_OUTPUT_BASE"

  
  let bazelPath: String

  
  let bazelBinPath: String
  private(set) lazy var bazelGenfilesPath: String = { [unowned self] in
    return self.bazelBinPath.replacingOccurrences(of: "-bin", with: "-genfiles")
  }()

  
  
  static let legacyTulsiIncludesPath = "_tulsi-includes/x/x"

  
  static let tulsiIncludesPath = "bazel-tulsi-includes/x/x"

  
  static let externalPrefix = "external/"

  let project: PBXProject
  let buildScriptPath: String
  let stubInfoPlistPaths: StubInfoPlistPaths
  let stubBinaryPaths: StubBinaryPaths
  let tulsiVersion: String
  let options: TulsiOptionSet
  let localizedMessageLogger: LocalizedMessageLogger
  let workspaceRootURL: URL
  let suppressCompilerDefines: Bool

  var bazelCleanScriptTarget: PBXLegacyTarget? = nil

  
  private struct IndexerData {
    
    
    
    
    struct NameInfoToken {
      let targetName: String
      let labelHash: Int

      init(ruleEntry: RuleEntry) {
        self.init(label: ruleEntry.label)
      }

      init(label: BuildLabel) {
        targetName = label.targetName!
        labelHash = label.hashValue
      }
    }

    let indexerNameInfo: [NameInfoToken]
    let dependencies: Set<BuildLabel>
    let resolvedDependencies: Set<RuleEntry>
    let preprocessorDefines: Set<String>
    let otherCFlags: [String]
    let otherSwiftFlags: [String]
    let includes: [String]
    let frameworkSearchPaths: [String]
    let swiftIncludePaths: [String]
    let deploymentTarget: DeploymentTarget
    let buildPhase: PBXSourcesBuildPhase
    let pchFile: BazelFileInfo?
    let bridgingHeader: BazelFileInfo?
    let enableModules: Bool

    
    static func deploymentTargetLabel(_ deploymentTarget: DeploymentTarget) -> String {
      return String(format: "%@_min%@",
                    deploymentTarget.platform.rawValue,
                    deploymentTarget.osVersion)
    }

    
    var deploymentTargetLabel: String {
      return IndexerData.deploymentTargetLabel(deploymentTarget)
    }

    
    var indexerName: String {
      var fullName = ""
      var fullHash = 0

      for token in indexerNameInfo {
        if fullName.isEmpty {
          fullName = token.targetName
        } else {
          fullName += "_\(token.targetName)"
        }
        fullHash = fullHash &+ token.labelHash
      }
      return PBXTargetGenerator.indexerNameForTargetName(fullName,
                                                         hash: fullHash,
                                                         suffix: deploymentTargetLabel)
    }

    
    
    var supportedIndexingTargets: [String] {
      var supportedTargets = [indexerName]
      if indexerNameInfo.count > 1 {
        for token in indexerNameInfo {
          supportedTargets.append(PBXTargetGenerator.indexerNameForTargetName(token.targetName,
                                                                              hash: token.labelHash,
                                                                              suffix: deploymentTargetLabel))
        }
      }
      return supportedTargets
    }

    
    var indexerNamesForResolvedDependencies: [String] {
      let parentDeploymentTargetLabel = self.deploymentTargetLabel
      return resolvedDependencies.map() { entry in
        let deploymentTargetLabel: String
        if let deploymentTarget = entry.deploymentTarget {
          deploymentTargetLabel = IndexerData.deploymentTargetLabel(deploymentTarget)
        } else {
          deploymentTargetLabel = parentDeploymentTargetLabel
        }
        return PBXTargetGenerator.indexerNameForTargetName(entry.label.targetName!,
                                                           hash: entry.label.hashValue,
                                                           suffix: deploymentTargetLabel)
      }
    }

    
    func canMergeWith(_ other: IndexerData) -> Bool {
      if self.pchFile != other.pchFile || self.bridgingHeader != other.bridgingHeader {
        return false
      }

      if !(preprocessorDefines == other.preprocessorDefines &&
          enableModules == other.enableModules &&
          otherCFlags == other.otherCFlags &&
          otherSwiftFlags == other.otherSwiftFlags &&
          frameworkSearchPaths == other.frameworkSearchPaths &&
          includes == other.includes &&
          swiftIncludePaths == other.swiftIncludePaths &&
          deploymentTarget == other.deploymentTarget) {
        return false
      }

      return true
    }

    
    func merging(_ other: IndexerData) -> IndexerData {
      let newDependencies = dependencies.union(other.dependencies)
      let newResolvedDependencies = resolvedDependencies.union(other.resolvedDependencies)
      let newName = indexerNameInfo + other.indexerNameInfo
      let newBuildPhase = PBXSourcesBuildPhase()
      newBuildPhase.files = buildPhase.files + other.buildPhase.files

      return IndexerData(indexerNameInfo: newName,
                         dependencies: newDependencies,
                         resolvedDependencies: newResolvedDependencies,
                         preprocessorDefines: preprocessorDefines,
                         otherCFlags: otherCFlags,
                         otherSwiftFlags: otherSwiftFlags,
                         includes: includes,
                         frameworkSearchPaths: frameworkSearchPaths,
                         swiftIncludePaths: swiftIncludePaths,
                         deploymentTarget: deploymentTarget,
                         buildPhase: newBuildPhase,
                         pchFile: pchFile,
                         bridgingHeader: bridgingHeader,
                         enableModules: enableModules)
    }
  }

  
  private var staticIndexers = [String: IndexerData]()
  
  private var frameworkIndexers = [String: IndexerData]()

  
  
  
  private var indexerTargetByName = [String: PBXTarget]()

  static func workingDirectoryForPBXGroup(_ group: PBXGroup) -> String {
    switch group.sourceTree {
      case .SourceRoot:
        if let relativePath = group.path, !relativePath.isEmpty {
          return "${SRCROOT}/\(relativePath)"
        }
        return ""

      case .Absolute:
        return group.path!

      default:
        assertionFailure("Group has an unexpected sourceTree type \(group.sourceTree)")
        return ""
    }
  }

  static func mainGroupForOutputFolder(_ outputFolderURL: URL, workspaceRootURL: URL) -> PBXGroup {
    let outputFolder = outputFolderURL.path
    let workspaceRoot = workspaceRootURL.path

    let slashTerminatedOutputFolder = outputFolder + (outputFolder.hasSuffix("/") ? "" : "/")
    let slashTerminatedWorkspaceRoot = workspaceRoot + (workspaceRoot.hasSuffix("/") ? "" : "/")

    
    if slashTerminatedOutputFolder == slashTerminatedWorkspaceRoot {
      return PBXGroup(name: "mainGroup", path: nil, sourceTree: .SourceRoot, parent: nil)
    }

    
    
    if workspaceRoot.hasPrefix(slashTerminatedOutputFolder) {
      let index = workspaceRoot.index(workspaceRoot.startIndex, offsetBy: slashTerminatedOutputFolder.count)
      let relativePath = String(workspaceRoot[index...])
      return PBXGroup(name: "mainGroup",
                      path: relativePath,
                      sourceTree: .SourceRoot,
                      parent: nil)
    }

    
    
    if outputFolder.hasPrefix(slashTerminatedWorkspaceRoot) {
      let index = outputFolder.index(outputFolder.startIndex, offsetBy: slashTerminatedWorkspaceRoot.count + 1)
      let pathToWalkBackUp = String(outputFolder[index...]) as NSString
      let numberOfDirectoriesToWalk = pathToWalkBackUp.pathComponents.count
      let relativePath = [String](repeating: "..", count: numberOfDirectoriesToWalk).joined(separator: "/")
      return PBXGroup(name: "mainGroup",
                      path: relativePath,
                      sourceTree: .SourceRoot,
                      parent: nil)
    }

    return PBXGroup(name: "mainGroup",
                    path: workspaceRootURL.path,
                    sourceTree: .Absolute,
                    parent: nil)
  }

  
  private static func projectRefForBazelFileInfo(_ info: BazelFileInfo) -> String {
    switch info.targetType {
      case .generatedFile:
        return "$(\(WorkspaceRootVarName))/\(info.fullPath)"
      case .sourceFile:
        return "$(\(BazelExecutionRootSymlinkVarName))/\(info.fullPath)"
    }
  }

  
  
  private static func defaultDeploymentTarget() -> DeploymentTarget {
    return DeploymentTarget(platform: .ios, osVersion: "9.0")
  }

  
  
  var improvedImportAutocompletionFix: Bool {
    return options[.ImprovedImportAutocompletionFix].commonValueAsBool ?? true
  }

  init(bazelPath: String,
       bazelBinPath: String,
       project: PBXProject,
       buildScriptPath: String,
       stubInfoPlistPaths: StubInfoPlistPaths,
       stubBinaryPaths: StubBinaryPaths,
       tulsiVersion: String,
       options: TulsiOptionSet,
       localizedMessageLogger: LocalizedMessageLogger,
       workspaceRootURL: URL,
       suppressCompilerDefines: Bool = false) {
    self.bazelPath = bazelPath
    self.bazelBinPath = bazelBinPath
    self.project = project
    self.buildScriptPath = buildScriptPath
    self.stubInfoPlistPaths = stubInfoPlistPaths
    self.stubBinaryPaths = stubBinaryPaths
    self.tulsiVersion = tulsiVersion
    self.options = options
    self.localizedMessageLogger = localizedMessageLogger
    self.workspaceRootURL = workspaceRootURL
    self.suppressCompilerDefines = suppressCompilerDefines
  }

  func generateFileReferencesForFilePaths(_ paths: [String], pathFilters: Set<String>?) {
    if let pathFilters = pathFilters {
      let filteredPaths = paths.filter(pathFilterFunc(pathFilters))
      project.getOrCreateGroupsAndFileReferencesForPaths(filteredPaths)
    } else {
      project.getOrCreateGroupsAndFileReferencesForPaths(paths)
    }
  }

  
  
  
  
  func registerRuleEntryForIndexer(_ ruleEntry: RuleEntry,
                                   ruleEntryMap: RuleEntryMap,
                                   pathFilters: Set<String>,
                                   processedEntries: inout [RuleEntry: (NSOrderedSet)]) {
    let includePathInProject = pathFilterFunc(pathFilters)
    func includeFileInProject(_ info: BazelFileInfo) -> Bool {
      return includePathInProject(info.fullPath)
    }

    func addFileReference(_ info: BazelFileInfo) {
      let (_, fileReferences) = project.getOrCreateGroupsAndFileReferencesForPaths([info.fullPath])
      fileReferences.first!.isInputFile = info.targetType == .sourceFile
    }

    func addBuildFileForRule(_ ruleEntry: RuleEntry) {
      guard let buildFilePath = ruleEntry.buildFilePath, includePathInProject(buildFilePath) else {
        return
      }
      project.getOrCreateGroupsAndFileReferencesForPaths([buildFilePath])
    }

    
    
    var ruleEntryLabelsToSkipForIndexing = Set<BuildLabel>()
    func addTestDepsToSkipList(_ ruleEntry: RuleEntry) {
      if ruleEntry.pbxTargetType?.isTest ?? false {
        for dep in ruleEntry.dependencies {
          ruleEntryLabelsToSkipForIndexing.insert(dep)
          guard let depEntry = ruleEntryMap.ruleEntry(buildLabel: dep, depender: ruleEntry) else {
            localizedMessageLogger.warning("UnknownTargetRule",
                                           comment: "Failure to look up a Bazel target that was expected to be present. The target label is %1$@",
                                           values: dep.value)
            continue
          }
          addTestDepsToSkipList(depEntry)
        }
      }
    }
    addTestDepsToSkipList(ruleEntry)

    
    
    @discardableResult
    func generateIndexerTargetGraphForRuleEntry(_ ruleEntry: RuleEntry) -> (NSOrderedSet) {
      if let data = processedEntries[ruleEntry] {
        return data
      }
      let frameworkSearchPaths = NSMutableOrderedSet()

      defer {
        processedEntries[ruleEntry] = (frameworkSearchPaths)
      }

      var resolvedDependecies = [RuleEntry]()
      for dep in ruleEntry.dependencies {
        guard let depEntry = ruleEntryMap.ruleEntry(buildLabel: dep, depender: ruleEntry) else {
          localizedMessageLogger.warning("UnknownTargetRule",
                                         comment: "Failure to look up a Bazel target that was expected to be present. The target label is %1$@",
                                         values: dep.value)
          continue
        }

        resolvedDependecies.append(depEntry)
        let inheritedFrameworkSearchPaths = generateIndexerTargetGraphForRuleEntry(depEntry)
        frameworkSearchPaths.union(inheritedFrameworkSearchPaths)
      }
      var defines = Set<String>()
      if let ruleDefines = ruleEntry.objcDefines {
        defines.formUnion(ruleDefines)
      }

      if !suppressCompilerDefines,
         let ruleDefines = ruleEntry.attributes[.compiler_defines] as? [String], !ruleDefines.isEmpty {
        defines.formUnion(ruleDefines)
      }

      let includes = NSMutableOrderedSet()
      addIncludes(ruleEntry, toSet: includes)

      
      
      
      ruleEntry.frameworkImports.forEach() {
        let fullPath = $0.fullPath as NSString
        let rootedPath = "$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\(fullPath.deletingLastPathComponent)"
        frameworkSearchPaths.add(rootedPath)
      }
      let sourceFileInfos = ruleEntry.sourceFiles.filter(includeFileInProject)
      let nonARCSourceFileInfos = ruleEntry.nonARCSourceFiles.filter(includeFileInProject)
      let frameworkFileInfos = ruleEntry.frameworkImports.filter(includeFileInProject)
      let nonSourceVersionedFileInfos = ruleEntry.versionedNonSourceArtifacts.filter(includeFileInProject)

      for target in ruleEntry.normalNonSourceArtifacts.filter(includeFileInProject) {
        let path = target.fullPath
        let (_, ref) = project.createGroupsAndFileReferenceForPath(path, underGroup: project.mainGroup)
        ref.isInputFile = target.targetType == .sourceFile
      }

      
      
      
      
      
      if (sourceFileInfos.isEmpty &&
          nonARCSourceFileInfos.isEmpty &&
          frameworkFileInfos.isEmpty &&
          nonSourceVersionedFileInfos.isEmpty)
        || ruleEntry.pbxTargetType?.isTest ?? false
        || ruleEntry.type == "filegroup"
        || ruleEntryLabelsToSkipForIndexing.contains(ruleEntry.label) {
        addBuildFileForRule(ruleEntry)
        return (frameworkSearchPaths)
      }

      var localPreprocessorDefines = defines
      let localIncludes = includes.mutableCopy() as! NSMutableOrderedSet
      let otherCFlags = NSMutableArray()
      let swiftIncludePaths = NSMutableOrderedSet()
      let otherSwiftFlags = NSMutableArray()
      addLocalSettings(ruleEntry, localDefines: &localPreprocessorDefines, localIncludes: localIncludes,
                       otherCFlags: otherCFlags, swiftIncludePaths: swiftIncludePaths, otherSwiftFlags: otherSwiftFlags)

      addOtherSwiftFlags(ruleEntry, toArray: otherSwiftFlags)
      addSwiftIncludes(ruleEntry, toSet: swiftIncludePaths)

      let pchFile = BazelFileInfo(info: ruleEntry.attributes[.pch])
      if let pchFile = pchFile, includeFileInProject(pchFile) {
        addFileReference(pchFile)
      }

      let bridgingHeader = BazelFileInfo(info: ruleEntry.attributes[.bridging_header])
      if let bridgingHeader = bridgingHeader, includeFileInProject(bridgingHeader) {
        addFileReference(bridgingHeader)
      }
      let enableModules = (ruleEntry.attributes[.enable_modules] as? Bool) == true

      addBuildFileForRule(ruleEntry)

      let (nonARCFiles, nonARCSettings) = generateFileReferencesAndSettingsForNonARCFileInfos(nonARCSourceFileInfos)
      var fileReferences = generateFileReferencesForFileInfos(sourceFileInfos)
      fileReferences.append(contentsOf: generateFileReferencesForFileInfos(frameworkFileInfos))
      fileReferences.append(contentsOf: nonARCFiles)

      var buildPhaseReferences: [PBXReference]
      if nonSourceVersionedFileInfos.isEmpty {
        buildPhaseReferences = [PBXReference]()
      } else {
        let versionedFileReferences = createReferencesForVersionedFileTargets(nonSourceVersionedFileInfos)
        buildPhaseReferences = versionedFileReferences as [PBXReference]
      }
      buildPhaseReferences.append(contentsOf: fileReferences as [PBXReference])

      let buildPhase = createBuildPhaseForReferences(buildPhaseReferences,
                                                     withPerFileSettings: nonARCSettings)

      if !buildPhase.files.isEmpty {
        let resolvedIncludes = localIncludes.array as! [String]

        let deploymentTarget: DeploymentTarget
        if let ruleDeploymentTarget = ruleEntry.deploymentTarget {
          deploymentTarget = ruleDeploymentTarget
        } else {
          deploymentTarget = PBXTargetGenerator.defaultDeploymentTarget()
          localizedMessageLogger.warning("NoDeploymentTarget",
                                         comment: "Rule Entry for %1$@ has no DeploymentTarget set. Defaulting to iOS 9.",
                                         values: ruleEntry.label.value)
        }

        let indexerData = IndexerData(indexerNameInfo: [IndexerData.NameInfoToken(ruleEntry: ruleEntry)],
                                      dependencies: ruleEntry.dependencies,
                                      resolvedDependencies: Set(resolvedDependecies),
                                      preprocessorDefines: localPreprocessorDefines,
                                      otherCFlags: otherCFlags as! [String],
                                      otherSwiftFlags: otherSwiftFlags as! [String],
                                      includes: resolvedIncludes,
                                      frameworkSearchPaths: frameworkSearchPaths.array as! [String],
                                      swiftIncludePaths: swiftIncludePaths.array as! [String],
                                      deploymentTarget: deploymentTarget,
                                      buildPhase: buildPhase,
                                      pchFile: pchFile,
                                      bridgingHeader: bridgingHeader,
                                      enableModules: enableModules)
        let isSwiftRule = ruleEntry.attributes[.has_swift_info] as? Bool ?? false
        if (isSwiftRule) {
          frameworkIndexers[indexerData.indexerName] = indexerData
        } else {
          staticIndexers[indexerData.indexerName] = indexerData
        }
      }

      return (frameworkSearchPaths)
    }

    generateIndexerTargetGraphForRuleEntry(ruleEntry)
  }

  @discardableResult
  func generateIndexerTargets() -> [String: PBXTarget] {
    mergeRegisteredIndexers()

    func generateIndexer(_ name: String,
                         indexerType: PBXTarget.ProductType,
                         data: IndexerData) {
      let indexingTarget = project.createNativeTarget(name,
                                                      deploymentTarget: nil,
                                                      targetType: indexerType,
                                                      isIndexerTarget: true)
      indexingTarget.buildPhases.append(data.buildPhase)
      addConfigsForIndexingTarget(indexingTarget, data: data)

      for name in data.supportedIndexingTargets {
        indexerTargetByName[name] = indexingTarget
      }
    }

    for (name, data) in staticIndexers {
      generateIndexer(name, indexerType: PBXTarget.ProductType.StaticLibrary, data: data)
    }

    for (name, data) in frameworkIndexers {
      generateIndexer(name, indexerType: PBXTarget.ProductType.Framework, data: data)
    }

    func linkDependencies(_ dataMap: [String: IndexerData]) {
      for (name, data) in dataMap {
        guard let indexerTarget = indexerTargetByName[name] else {
          localizedMessageLogger.infoMessage("Unexpectedly failed to resolve indexer \(name)")
          continue
        }

        for depName in data.indexerNamesForResolvedDependencies {
          guard let indexerDependency = indexerTargetByName[depName], indexerDependency !== indexerTarget else {
            continue
          }

          indexerTarget.createDependencyOn(indexerDependency,
                                           proxyType: PBXContainerItemProxy.ProxyType.targetReference,
                                           inProject: project)
        }
      }
    }

    linkDependencies(staticIndexers)
    linkDependencies(frameworkIndexers)

    return indexerTargetByName
  }

  func generateBazelCleanTarget(_ scriptPath: String, workingDirectory: String = "",
                                startupOptions: [String] = []) {
    assert(bazelCleanScriptTarget == nil, "generateBazelCleanTarget may only be called once")

    let allArgs = [bazelPath, bazelBinPath] + startupOptions
    let buildArgs = allArgs.map { "\"\($0)\""}.joined(separator: " ")

    bazelCleanScriptTarget = project.createLegacyTarget(PBXTargetGenerator.BazelCleanTarget,
                                                        deploymentTarget: nil,
                                                        buildToolPath: "\(scriptPath)",
                                                        buildArguments: buildArgs,
                                                        buildWorkingDirectory: workingDirectory)

    for target: PBXTarget in project.allTargets {
      if target === bazelCleanScriptTarget {
        continue
      }

      target.createDependencyOn(bazelCleanScriptTarget!,
                                proxyType: PBXContainerItemProxy.ProxyType.targetReference,
                                inProject: project,
                                first: true)
    }
  }

  func generateTopLevelBuildConfigurations(_ buildSettingOverrides: [String: String] = [:]) {
    var buildSettings = options.commonBuildSettings()

    for (key, value) in buildSettingOverrides {
      buildSettings[key] = value
    }

    buildSettings["ONLY_ACTIVE_ARCH"] = "YES"
    // Fixes an Xcode "Upgrade to recommended settings" warning. Technically the warning only
    
    
    buildSettings["ENABLE_TESTABILITY"] = "YES"

    
    
    
    buildSettings["CLANG_ENABLE_OBJC_ARC"] = "YES"

    
    buildSettings["CODE_SIGNING_REQUIRED"] = "NO"
    buildSettings["CODE_SIGN_IDENTITY"] = ""
    
    if !options.useLegacyBuildSystem {
      buildSettings["CODE_SIGNING_ALLOWED"] = "NO"
    }

    
    
    buildSettings["FRAMEWORK_SEARCH_PATHS"] = "$(PLATFORM_DIR)/Developer/Library/Frameworks";

    
    buildSettings["DONT_RUN_SWIFT_STDLIB_TOOL"] = "YES"

    var sourceDirectory = PBXTargetGenerator.workingDirectoryForPBXGroup(project.mainGroup)
    if sourceDirectory.isEmpty {
      sourceDirectory = "$(SRCROOT)"
    }

    
    buildSettings["\(PBXTargetGenerator.WorkspaceRootVarName)"] = sourceDirectory

    
    
    
    
    
    buildSettings[PBXTargetGenerator.BazelExecutionRootSymlinkVarName] =
        "$(PROJECT_FILE_PATH)/\(PBXTargetGenerator.TulsiExecutionRootSymlinkPath)"
    buildSettings[PBXTargetGenerator.BazelExecutionRootSymlinkLegacyVarName] =
        "$(PROJECT_FILE_PATH)/\(PBXTargetGenerator.TulsiExecutionRootSymlinkPath)"
    buildSettings[PBXTargetGenerator.BazelOutputBaseSymlinkVarName] =
        "$(PROJECT_FILE_PATH)/\(PBXTargetGenerator.TulsiOutputBaseSymlinkPath)"

    buildSettings["TULSI_VERSION"] = tulsiVersion

    
    
    
    buildSettings["PYTHONIOENCODING"] = "utf8"

    let searchPaths = ["$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))",
                       "$(\(PBXTargetGenerator.WorkspaceRootVarName))/\(bazelBinPath)",
                       "$(\(PBXTargetGenerator.WorkspaceRootVarName))/\(bazelGenfilesPath)",
                       "$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\(PBXTargetGenerator.tulsiIncludesPath)"
    ]
    
    
    buildSettings["HEADER_SEARCH_PATHS"] = searchPaths.joined(separator: " ")

    
    if !options.useLegacyBuildSystem {
      buildSettings["CC"] = stubBinaryPaths.clang
      buildSettings["CXX"] = stubBinaryPaths.clang
      buildSettings["LD"] = stubBinaryPaths.ld
      buildSettings["LDPLUSPLUS"] = stubBinaryPaths.ld
      buildSettings["SWIFT_EXEC"] = stubBinaryPaths.swiftc
    }

    createBuildConfigurationsForList(project.buildConfigurationList, buildSettings: buildSettings)
    addTestRunnerBuildConfigurationToBuildConfigurationList(project.buildConfigurationList)
  }

  
  func generateBuildTargetsForRuleEntries(
    _ ruleEntries: Set<RuleEntry>,
    ruleEntryMap: RuleEntryMap,
    pathFilters: Set<String>?
  ) throws -> [BuildLabel: PBXNativeTarget] {
    let namedRuleEntries = generateUniqueNamesForRuleEntries(ruleEntries)

    let progressNotifier = ProgressNotifier(name: GeneratingBuildTargets,
                                            maxValue: namedRuleEntries.count)

    var testTargetLinkages = [(PBXNativeTarget, BuildLabel?, RuleEntry)]()
    var watchAppTargets = [String: (PBXNativeTarget, RuleEntry)]()
    var watchExtensionsByEntry = [RuleEntry: PBXNativeTarget]()
    var targetsByLabel = [BuildLabel: PBXNativeTarget]()

    for (name, entry) in namedRuleEntries {
      progressNotifier.incrementValue()
      let target = try createBuildTargetForRuleEntry(entry,
                                                     named: name,
                                                     ruleEntryMap: ruleEntryMap)
      targetsByLabel[entry.label] = target

      if let script = options[.PreBuildPhaseRunScript, entry.label.value] {
        let runScript = PBXShellScriptBuildPhase(
          shellScript: script,
          shellPath: "/bin/bash",
          name: "Pre-build Run Script")
        runScript.showEnvVarsInLog = true
        target.buildPhases.insert(runScript, at: 0)
      }

      if let script = options[.PostBuildPhaseRunScript, entry.label.value] {
        let runScript = PBXShellScriptBuildPhase(
          shellScript: script,
          shellPath: "/bin/bash",
          name: "Post-build Run Script")
        runScript.showEnvVarsInLog = true
        target.buildPhases.append(runScript)
      }

      if let hostLabelString = entry.attributes[.test_host] as? String {
        let hostLabel = BuildLabel(hostLabelString)
        testTargetLinkages.append((target, hostLabel, entry))
      } else if entry.pbxTargetType == .UnitTest {
        
        
        testTargetLinkages.append((target, nil, entry))
      }

      switch entry.pbxTargetType {
      case .Watch2App?:
        watchAppTargets[name] = (target, entry)
      case .Watch2Extension?:
        watchExtensionsByEntry[entry] = target
      default:
        break
      }
    }

    
    for (_, (watchAppTarget, watchRuleEntry)) in watchAppTargets {
      for ext in watchRuleEntry.extensions {
        if let extEntry = ruleEntryMap.ruleEntry(buildLabel: ext, depender: watchRuleEntry),
            extEntry.pbxTargetType == .Watch2Extension {
          if let watchExtensionTarget = watchExtensionsByEntry[extEntry] {
            watchAppTarget.createDependencyOn(watchExtensionTarget, proxyType: .targetReference, inProject: project)
          } else {
            localizedMessageLogger.warning("FindingWatchExtensionFailed",
                                           comment: "Message to show when the watchOS app extension %1$@ could not be found and the resulting project will not be able to launch the watch app.",
                                           values: extEntry.label.value)
          }
        }
      }
    }

    for (testTarget, testHostLabel, entry) in testTargetLinkages {
      let testHostTarget: PBXNativeTarget?
      if let hostTargetLabel = testHostLabel {
        testHostTarget = targetsByLabel[hostTargetLabel]
        if testHostTarget == nil {
          
          
          
          localizedMessageLogger.warning("MissingTestHost",
                                         comment: "Warning to show when a user has selected an XCTest but not its host application.",
                                         values: entry.label.value, hostTargetLabel.value)
          continue
        }
      } else {
        testHostTarget = nil
      }
      updateTestTarget(testTarget,
                       withLinkageToHostTarget: testHostTarget,
                       ruleEntry: entry,
                       ruleEntryMap: ruleEntryMap,
                       pathFilters: pathFilters)
    }
    return targetsByLabel
  }

  

  
  
  private func pathFilterFunc(_ pathFilters: Set<String>?) -> (String) -> Bool {
    guard let pathFilters = pathFilters else {
      return { (path: String) -> Bool in
        return true
      }
    }
    let recursiveFilters = Set<String>(pathFilters.filter({ $0.hasSuffix("/...") }).map() {
      let index = $0.index($0.endIndex, offsetBy: -3)
      return String($0[..<index])
    })

    func includePath(_ path: String) -> Bool {
      let dir = (path as NSString).deletingLastPathComponent
      if pathFilters.contains(dir) { return true }
      let terminatedDir = dir + "/"
      for filter in recursiveFilters {
        if terminatedDir.hasPrefix(filter) { return true }
      }
      return false
    }

    return includePath
  }

  
  private func mergeRegisteredIndexers() {

    func mergeIndexers<T : Sequence>(_ indexers: T) -> [String: IndexerData] where T.Iterator.Element == IndexerData {
      var mergedIndexers = [String: IndexerData]()
      var indexers = Array(indexers).sorted { $0.indexerName < $1.indexerName }

      while !indexers.isEmpty {
        var remaining = [IndexerData]()
        var d1 = indexers.popLast()!
        for d2 in indexers {
          if d1.canMergeWith(d2) {
            d1 = d1.merging(d2)
          } else {
            remaining.append(d2)
          }
        }

        mergedIndexers[d1.indexerName] = d1
        indexers = remaining
      }

      return mergedIndexers
    }

    staticIndexers = mergeIndexers(staticIndexers.values)
    frameworkIndexers = mergeIndexers(frameworkIndexers.values)
  }

  private func generateFileReferencesForFileInfos(_ infos: [BazelFileInfo]) -> [PBXFileReference] {
    guard !infos.isEmpty else { return [] }
    var generatedFilePaths = [String]()
    var sourceFilePaths = [String]()
    for info in infos {
      switch info.targetType {
        case .generatedFile:
          generatedFilePaths.append(info.fullPath)
        case .sourceFile:
          sourceFilePaths.append(info.fullPath)
      }
    }

    
    var (_, fileReferences) = project.getOrCreateGroupsAndFileReferencesForPaths(sourceFilePaths)
    let (_, generatedFileReferences) = project.getOrCreateGroupsAndFileReferencesForPaths(generatedFilePaths)
    generatedFileReferences.forEach() { $0.isInputFile = false }

    fileReferences.append(contentsOf: generatedFileReferences)
    return fileReferences
  }

  
  
  private func generateFileReferencesAndSettingsForNonARCFileInfos(_ infos: [BazelFileInfo]) -> ([PBXFileReference], [PBXFileReference: [String: String]]) {
    let nonARCFileReferences = generateFileReferencesForFileInfos(infos)
    var settings = [PBXFileReference: [String: String]]()
    let disableARCSetting = ["COMPILER_FLAGS": "-fno-objc-arc"]
    nonARCFileReferences.forEach() {
      settings[$0] = disableARCSetting
    }
    return (nonARCFileReferences, settings)
  }

  
  private func longestCommonPrefix(_ strings: Set<String>, separator: Character) -> String {
    
    guard strings.count >= 2, var shortestString = strings.first else { return "" }
    for str in strings {
      guard str.count < shortestString.count else { continue }
      shortestString = str
    }

    guard !shortestString.isEmpty else { return "" }

    
    var components = shortestString.split(separator: separator).dropLast()
    var potentialPrefix = "\(components.joined(separator: "\(separator)"))\(separator)"

    for str in strings {
      while !components.isEmpty && !str.hasPrefix(potentialPrefix) {
        components = components.dropLast()
        potentialPrefix = "\(components.joined(separator: "\(separator)"))\(separator)"
      }
    }
    return potentialPrefix
  }

  
  
  
  
  
  
  
  
  
  
  
  private func uniqueNames(for ruleEntries: Set<RuleEntry>,
                           named: inout [String: RuleEntry],
                           namer: (_ ruleEntry: RuleEntry) -> String?
  ) -> Set<RuleEntry> {
    var unnamed = Set<RuleEntry>()

    
    var ruleEntriesByName = [String: [RuleEntry]]()
    for entry in ruleEntries {
      guard let name = namer(entry) else {
        unnamed.insert(entry)
        continue
      }
      ruleEntriesByName[name, default: []].append(entry)
    }

    for (name, entries) in ruleEntriesByName {
      
      guard entries.count == 1 && named.index(forKey: name) == nil else {
        unnamed.formUnion(entries)
        continue
      }
      named[name] = entries.first!
    }
    return unnamed
  }

  
  
  private func generateUniqueNamesForRuleEntries(_ ruleEntries: Set<RuleEntry>) -> [String: RuleEntry] {
    var named = [String: RuleEntry]()
    
    var unnamed = self.uniqueNames(for: ruleEntries, named: &named) { $0.bundleName }
    unnamed = self.uniqueNames(for: unnamed, named: &named) {
      $0.label.targetName
    }

    
    guard !unnamed.isEmpty else {
      return named
    }

    
    let conflictingFullNames = Set(unnamed.map {
      $0.label.asFullPBXTargetName!
    })

    
    let commonPrefix = self.longestCommonPrefix(conflictingFullNames, separator: "-")

    guard !commonPrefix.isEmpty else {
      for entry in unnamed {
        let fullName = entry.label.asFullPBXTargetName!
        named[fullName] = entry
      }
      return named
    }

    
    let charsToDrop = commonPrefix.count
    for entry in unnamed {
      let fullName = entry.label.asFullPBXTargetName!
      let shortenedFullName = String(fullName.dropFirst(charsToDrop))
      guard !shortenedFullName.isEmpty && named.index(forKey: shortenedFullName) == nil else {
        named[fullName] = entry
        continue
      }
      named[shortenedFullName] = entry
    }

    return named
  }

  
  private func createReferencesForVersionedFileTargets(_ fileInfos: [BazelFileInfo]) -> [XCVersionGroup] {
    var groups = [String: XCVersionGroup]()

    for info in fileInfos {
      let path = info.fullPath as NSString
      let versionedGroupPath = path.deletingLastPathComponent
      let type = info.subPath.pbPathUTI ?? ""
      let versionedGroup = project.getOrCreateVersionGroupForPath(versionedGroupPath,
                                                                  versionGroupType: type)
      if groups[versionedGroupPath] == nil {
        groups[versionedGroupPath] = versionedGroup
      }
      let ref = versionedGroup.getOrCreateFileReferenceBySourceTree(.Group,
                                                                    path: path as String)
      ref.isInputFile = info.targetType == .sourceFile
    }

    for (sourcePath, group) in groups {
      setCurrentVersionForXCVersionGroup(group, atPath: sourcePath)
    }
    return Array(groups.values)
  }

  
  
  
  private func setCurrentVersionForXCVersionGroup(_ group: XCVersionGroup,
                                                  atPath sourcePath: String) {

    let versionedBundleURL = workspaceRootURL.appendingPathComponent(sourcePath,
                                                                     isDirectory: true)
    let currentVersionPlistURL = versionedBundleURL.appendingPathComponent(".xccurrentversion",
                                                                           isDirectory: false)
    let path = currentVersionPlistURL.path
    guard let data = FileManager.default.contents(atPath: path) else {
      self.localizedMessageLogger.warning("LoadingXCCurrentVersionFailed",
                                          comment: "Message to show when loading a .xccurrentversion file fails.",
                                          values: group.name, "Version file at '\(path)' could not be read")
      return
    }

    do {
      let plist = try PropertyListSerialization.propertyList(from: data,
                                                                       options: PropertyListSerialization.MutabilityOptions(),
                                                                       format: nil) as! [String: AnyObject]
      if let currentVersion = plist["_XCCurrentVersionName"] as? String {
        if !group.setCurrentVersionByName(currentVersion) {
          self.localizedMessageLogger.warning("LoadingXCCurrentVersionFailed",
                                              comment: "Message to show when loading a .xccurrentversion file fails.",
                                              values: group.name, "Version '\(currentVersion)' specified by file at '\(path)' was not found")
        }
      }
    } catch let e as NSError {
      self.localizedMessageLogger.warning("LoadingXCCurrentVersionFailed",
                                          comment: "Message to show when loading a .xccurrentversion file fails.",
                                          values: group.name, "Version file at '\(path)' is invalid: \(e)")
    } catch {
      self.localizedMessageLogger.warning("LoadingXCCurrentVersionFailed",
                                          comment: "Message to show when loading a .xccurrentversion file fails.",
                                          values: group.name, "Version file at '\(path)' is invalid.")
    }
  }

  
  
  // spaces, the key will be escaped (e.g. -Dfoo bar becomes -D"foo bar").
  private func addConfigsForIndexingTarget(_ target: PBXTarget, data: IndexerData) {

    var buildSettings = options.buildSettingsForTarget(target.name)
    buildSettings["PRODUCT_NAME"] = target.productName!

    if let pchFile = data.pchFile {
      buildSettings["GCC_PREFIX_HEADER"] = PBXTargetGenerator.projectRefForBazelFileInfo(pchFile)
    }

    var allOtherCFlags = data.otherCFlags.filter { !$0.hasPrefix("-W") }
    // Escape the spaces in the defines by transforming -Dfoo bar into -D"foo bar".
    if !data.preprocessorDefines.isEmpty {
      allOtherCFlags.append(contentsOf: data.preprocessorDefines.sorted().map { define in
        
        if define.rangeOfCharacter(from: .whitespaces) != nil &&
            !((define.hasPrefix("\"") && define.hasSuffix("\"")) ||
              (define.hasPrefix("'") && define.hasSuffix("'"))) {
          return "-D\"\(define)\""
        }
        return "-D\(define)"
      })
    }

    if !allOtherCFlags.isEmpty {
      buildSettings["OTHER_CFLAGS"] = allOtherCFlags.joined(separator: " ")
    }

    if let bridgingHeader = data.bridgingHeader {
      buildSettings["SWIFT_OBJC_BRIDGING_HEADER"] = PBXTargetGenerator.projectRefForBazelFileInfo(bridgingHeader)
    }

    if data.enableModules {
      buildSettings["CLANG_ENABLE_MODULES"] = "YES"
    }

    if !data.includes.isEmpty {
      let includes = data.includes.joined(separator: " ")
      buildSettings["HEADER_SEARCH_PATHS"] = "$(inherited) \(includes) "
    }

    if !data.frameworkSearchPaths.isEmpty {
      buildSettings["FRAMEWORK_SEARCH_PATHS"] = "$(inherited) " + data.frameworkSearchPaths.joined(separator: " ")
    }

    if !data.swiftIncludePaths.isEmpty {
      let paths = data.swiftIncludePaths.joined(separator: " ")
      buildSettings["SWIFT_INCLUDE_PATHS"] = "$(inherited) \(paths)"
    }

    if !data.otherSwiftFlags.isEmpty {
      buildSettings["OTHER_SWIFT_FLAGS"] = "$(inherited) " + data.otherSwiftFlags.joined(separator: " ")
    }

    
    
    if self.improvedImportAutocompletionFix, let nativeTarget = target as? PBXNativeTarget,
       nativeTarget.productType == .StaticLibrary {
      buildSettings["USER_HEADER_SEARCH_PATHS"] = "$(\(PBXTargetGenerator.WorkspaceRootVarName))"
    }

    
    
    
    
    
    
    
    let deploymentTarget = data.deploymentTarget
    let platform = deploymentTarget.platform
    buildSettings["SDKROOT"] = platform.deviceSDK
    buildSettings[platform.buildSettingsDeploymentTarget] = deploymentTarget.osVersion

    createBuildConfigurationsForList(target.buildConfigurationList,
                                     buildSettings: buildSettings,
                                     indexerSettingsOnly: true)
  }

  /// Updates the build settings and optionally adds a "Compile sources" phase for the given test
  
  private func updateTestTarget(_ target: PBXNativeTarget,
                                withLinkageToHostTarget hostTarget: PBXNativeTarget?,
                                ruleEntry: RuleEntry,
                                ruleEntryMap: RuleEntryMap,
                                pathFilters: Set<String>?) {
    
    if let hostTarget = hostTarget {
      project.linkTestTarget(target, toHostTarget: hostTarget)
    }
    updateTestTargetIndexer(target, ruleEntry: ruleEntry, hostTarget: hostTarget, ruleEntryMap: ruleEntryMap)
    updateTestTargetBuildPhases(target, ruleEntry: ruleEntry, ruleEntryMap: ruleEntryMap, pathFilters: pathFilters)
  }

  
  private func updateTestTargetIndexer(_ target: PBXNativeTarget,
                                       ruleEntry: RuleEntry,
                                       hostTarget: PBXNativeTarget?,
                                       ruleEntryMap: RuleEntryMap) {
    let testSettings = targetTestSettings(target, hostTarget: hostTarget, ruleEntry: ruleEntry, ruleEntryMap: ruleEntryMap)

    
    let deploymentTarget = ruleEntry.deploymentTarget ?? PBXTargetGenerator.defaultDeploymentTarget()
    let deploymentTargetLabel = IndexerData.deploymentTargetLabel(deploymentTarget)
    let indexerName = PBXTargetGenerator.indexerNameForTargetName(ruleEntry.label.targetName!,
                                                                  hash: ruleEntry.label.hashValue,
                                                                  suffix: deploymentTargetLabel)
    let indexerTarget = indexerTargetByName[indexerName]
    updateMissingBuildConfigurationsForList(target.buildConfigurationList,
                                            withBuildSettings: testSettings,
                                            inheritingFromConfigurationList: indexerTarget?.buildConfigurationList,
                                            suppressingBuildSettings: ["ARCHS", "VALID_ARCHS"])
  }

  private func updateTestTargetBuildPhases(_ target: PBXNativeTarget,
                                           ruleEntry: RuleEntry,
                                           ruleEntryMap: RuleEntryMap,
                                           pathFilters: Set<String>?) {
    let includePathInProject = pathFilterFunc(pathFilters)
    func includeFileInProject(_ info: BazelFileInfo) -> Bool {
      return includePathInProject(info.fullPath)
    }
    let testSourceFileInfos = ruleEntry.sourceFiles.filter(includeFileInProject)
    let testNonArcSourceFileInfos = ruleEntry.nonARCSourceFiles.filter(includeFileInProject)
    let containsSwift = ruleEntry.attributes[.has_swift_dependency] as? Bool ?? false

    
    
    if containsSwift {
      let testBuildPhase = createGenerateSwiftDummyFilesTestBuildPhase()
      target.buildPhases.append(testBuildPhase)
    }
    if !testSourceFileInfos.isEmpty || !testNonArcSourceFileInfos.isEmpty {
      
      let allSources = testSourceFileInfos + testNonArcSourceFileInfos
      let nonSwiftSources = allSources.filter { !$0.subPath.hasSuffix(".swift") }
      if !nonSwiftSources.isEmpty {
        let testBuildPhase = createGenerateDummyDependencyFilesTestBuildPhase(nonSwiftSources)
        target.buildPhases.append(testBuildPhase)
      }
      var fileReferences = generateFileReferencesForFileInfos(testSourceFileInfos)
      let (nonARCFiles, nonARCSettings) =
          generateFileReferencesAndSettingsForNonARCFileInfos(testNonArcSourceFileInfos)
      fileReferences.append(contentsOf: nonARCFiles)
      let buildPhase = createBuildPhaseForReferences(fileReferences,
                                                     withPerFileSettings: nonARCSettings)
      target.buildPhases.append(buildPhase)
    }
  }

  
  private func addIncludes(_ ruleEntry: RuleEntry,
                           toSet includes: NSMutableOrderedSet) {
    if let includePaths = ruleEntry.includePaths {
      let rootedPaths: [String] = includePaths.map() { (path, recursive) in
        
        
        
        let prefixVar: String
        if path.hasPrefix(PBXTargetGenerator.tulsiIncludesPath) {
          prefixVar = PBXTargetGenerator.BazelExecutionRootSymlinkVarName
        } else if path.hasPrefix(PBXTargetGenerator.externalPrefix) {
          
          
          
          
          prefixVar = PBXTargetGenerator.BazelOutputBaseSymlinkVarName
        } else {
          prefixVar = PBXTargetGenerator.WorkspaceRootVarName
        }
        let rootedPath = "$(\(prefixVar))/\(path)"
        if recursive {
          return "\(rootedPath)/**"
        }
        return rootedPath
      }
      includes.addObjects(from: rootedPaths)
    }
  }

  
  private func addSwiftIncludes(_ ruleEntry: RuleEntry,
                                toSet swiftIncludes: NSMutableOrderedSet) {
    for module in ruleEntry.swiftTransitiveModules {
      let fullPath = module.fullPath as NSString
      let includePath = fullPath.deletingLastPathComponent
      swiftIncludes.add("$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\(includePath)")
    }
  }

  
  private func addOtherSwiftFlags(_ ruleEntry: RuleEntry, toArray swiftFlags: NSMutableArray) {
    
    
    
    
    swiftFlags.addObjects(from: ruleEntry.objCModuleMaps.map() {
      "-Xcc -fmodule-map-file=$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\($0.fullPath)"
    })

    if let swiftDefines = ruleEntry.swiftDefines {
      for flag in swiftDefines {
        swiftFlags.add("-D\(flag)")
      }
    }
  }

  
  private func addLocalSettings(_ ruleEntry: RuleEntry,
                                localDefines: inout Set<String>,
                                localIncludes: NSMutableOrderedSet,
                                otherCFlags: NSMutableArray,
                                swiftIncludePaths: NSMutableOrderedSet,
                                otherSwiftFlags: NSMutableArray) {
    if let swiftc_opts = ruleEntry.attributes[.swiftc_opts] as? [String], !swiftc_opts.isEmpty {
      for opt in swiftc_opts {
        if opt.hasPrefix("-I") {
          let index = opt.index(opt.startIndex, offsetBy: 2)
          var path = String(opt[index...])
          if !path.hasPrefix("/") {
            path = "$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\(path)"
          }
          swiftIncludePaths.add(path)
        } else {
          otherSwiftFlags.add(opt)
        }
      }
    }
    guard let copts = ruleEntry.attributes[.copts] as? [String], !copts.isEmpty else {
      return
    }
    for opt in copts {
      if opt.hasPrefix("-D") {
        let index = opt.index(opt.startIndex, offsetBy: 2)
        localDefines.insert(String(opt[index...]))
      } else if opt.hasPrefix("-I") {
        let index = opt.index(opt.startIndex, offsetBy: 2)
        var path = String(opt[index...])
        if !path.hasPrefix("/") {
          path = "$(\(PBXTargetGenerator.BazelExecutionRootSymlinkVarName))/\(path)"
        }
        localIncludes.add(path)
      } else {
        otherCFlags.add(opt)
      }
    }
  }

  
  private func targetTestSettings(_ target: PBXNativeTarget,
                                  hostTarget: PBXNativeTarget?,
                                  ruleEntry: RuleEntry,
                                  ruleEntryMap: RuleEntryMap) -> [String: String] {
    var testSettings = ["TULSI_TEST_RUNNER_ONLY": "YES"]
    
    
    if let hostTargetPath = hostTarget?.productReference?.path,
      let hostTargetProductName = hostTarget?.productName,
      let deploymentTarget = target.deploymentTarget {

      if target.productType == .UIUnitTest {
        testSettings["TEST_TARGET_NAME"] = hostTargetProductName
      } else if let testHostPath = deploymentTarget.platform.testHostPath(hostTargetPath: hostTargetPath,
                                                                          hostTargetProductName: hostTargetProductName) {
        testSettings["BUNDLE_LOADER"] = "$(TEST_HOST)"
        testSettings["TEST_HOST"] = testHostPath
      }
    }

    let includes = NSMutableOrderedSet()

    
    
    
    var defines = Set<String>()
    let swiftIncludePaths = NSMutableOrderedSet()
    let otherSwiftFlags = NSMutableArray()

    addIncludes(ruleEntry, toSet: includes)
    addLocalSettings(ruleEntry, localDefines: &defines, localIncludes: includes,
                     otherCFlags: NSMutableArray(), swiftIncludePaths: NSMutableOrderedSet(),
                     otherSwiftFlags: NSMutableArray())
    addSwiftIncludes(ruleEntry, toSet: swiftIncludePaths)
    addOtherSwiftFlags(ruleEntry, toArray: otherSwiftFlags)

    let includesArr = includes.array as! [String]
    if !includesArr.isEmpty {
      testSettings["HEADER_SEARCH_PATHS"] = "$(inherited) " + includesArr.joined(separator: " ")
    }

    if let swiftIncludes = swiftIncludePaths.array as? [String], !swiftIncludes.isEmpty {
      testSettings["SWIFT_INCLUDE_PATHS"] = "$(inherited) " + swiftIncludes.joined(separator: " ")
    }

    if let otherSwiftFlagsArr = otherSwiftFlags as? [String], !otherSwiftFlagsArr.isEmpty {
      testSettings["OTHER_SWIFT_FLAGS"] = "$(inherited) " + otherSwiftFlagsArr.joined(separator: " ")
    }

    if let moduleName = ruleEntry.moduleName {
      testSettings["PRODUCT_MODULE_NAME"] = moduleName
    }

    return testSettings
  }

  
  
  // into a "clang --version" invocation.
  private func addTestRunnerBuildConfigurationToBuildConfigurationList(_ list: XCConfigurationList) {

    func createTestConfigNamed(_ testConfigName: String,
                               forBaseConfigNamed configurationName: String) {
      let baseConfig = list.getOrCreateBuildConfiguration(configurationName)
      let config = list.getOrCreateBuildConfiguration(testConfigName)

      var runTestTargetBuildSettings = baseConfig.buildSettings
      
      runTestTargetBuildSettings["OTHER_CFLAGS"] = "--version"
      runTestTargetBuildSettings["OTHER_SWIFT_FLAGS"] = "--version"
      
      
      runTestTargetBuildSettings["OTHER_LDFLAGS"] = "--version"

      
      
      runTestTargetBuildSettings["SWIFT_OBJC_INTERFACE_HEADER_NAME"] = "$(PRODUCT_NAME).h"

      
      runTestTargetBuildSettings["SWIFT_INSTALL_OBJC_HEADER"] = "NO"

      
      
      runTestTargetBuildSettings["ONLY_ACTIVE_ARCH"] = "YES"

      
      
      runTestTargetBuildSettings["FRAMEWORK_SEARCH_PATHS"] = ""
      runTestTargetBuildSettings["HEADER_SEARCH_PATHS"] = ""

      config.buildSettings = runTestTargetBuildSettings
    }

    for (testConfigName, configName) in PBXTargetGenerator.testRunnerEnabledBuildConfigNames {
      createTestConfigNamed(testConfigName, forBaseConfigNamed: configName)
    }
  }

  private func createBuildConfigurationsForList(_ buildConfigurationList: XCConfigurationList,
                                                buildSettings: Dictionary<String, String>,
                                                indexerSettingsOnly: Bool = false) {
    func addPreprocessorDefine(_ define: String, toConfig config: XCBuildConfiguration) {
      if let existingDefinitions = config.buildSettings["GCC_PREPROCESSOR_DEFINITIONS"] {
        // NOTE(abaire): Technically this should probably check first to see if "define" has been
        
        
        config.buildSettings["GCC_PREPROCESSOR_DEFINITIONS"] = existingDefinitions + " \(define)"
      } else {
        config.buildSettings["GCC_PREPROCESSOR_DEFINITIONS"] = define
      }
    }

    for configName in PBXTargetGenerator.buildConfigNames {
      let config = buildConfigurationList.getOrCreateBuildConfiguration(configName)
      config.buildSettings = buildSettings

      
      if configName == "Debug" {
        addPreprocessorDefine("DEBUG=1", toConfig: config)
      } else if configName == "Release" {
        addPreprocessorDefine("NDEBUG=1", toConfig: config)
      }
    }
  }

  private func updateMissingBuildConfigurationsForList(_ buildConfigurationList: XCConfigurationList,
                                                       withBuildSettings newSettings: Dictionary<String, String>,
                                                       inheritingFromConfigurationList baseConfigurationList: XCConfigurationList? = nil,
                                                       suppressingBuildSettings suppressedKeys: Set<String> = []) {
    func mergeDictionary(_ old: inout [String: String],
                         withContentsOfDictionary new: [String: String]) {
      for (key, value) in new {
        if let _ = old[key] { continue }
        if suppressedKeys.contains(key) { continue }
        old.updateValue(value, forKey: key)
      }
    }

    for configName in PBXTargetGenerator.buildConfigNames {
      let config = buildConfigurationList.getOrCreateBuildConfiguration(configName)
      mergeDictionary(&config.buildSettings, withContentsOfDictionary: newSettings)

      if let baseSettings = baseConfigurationList?.getBuildConfiguration(configName)?.buildSettings {
        mergeDictionary(&config.buildSettings, withContentsOfDictionary: baseSettings)
      }
    }

    for (testRunnerConfigName, configName) in PBXTargetGenerator.testRunnerEnabledBuildConfigNames {
      let config = buildConfigurationList.getOrCreateBuildConfiguration(testRunnerConfigName)
      mergeDictionary(&config.buildSettings, withContentsOfDictionary: newSettings)

      if let baseSettings = baseConfigurationList?.getBuildConfiguration(testRunnerConfigName)?.buildSettings {
        mergeDictionary(&config.buildSettings, withContentsOfDictionary: baseSettings)
      } else if let baseSettings = baseConfigurationList?.getBuildConfiguration(configName)?.buildSettings {
        
        
        mergeDictionary(&config.buildSettings, withContentsOfDictionary: baseSettings)
      }
    }
  }

  static func indexerNameForTargetName(_ targetName: String, hash: Int, suffix: String?) -> String {
    let normalizedTargetName: String
    if targetName.count > MaxIndexerNameLength {
      let endIndex = targetName.index(targetName.startIndex, offsetBy: MaxIndexerNameLength - 4)
      normalizedTargetName = String(targetName[..<endIndex]) + "_etc"
    } else {
      normalizedTargetName = targetName
    }
    if let suffix = suffix {
      return String(format: "\(IndexerTargetPrefix)\(normalizedTargetName)_%08X_%@", hash, suffix)
    }
    return String(format: "\(IndexerTargetPrefix)\(normalizedTargetName)_%08X", hash)
  }

  
  
  private func createBuildPhaseForReferences(_ refs: [PBXReference],
                                             withPerFileSettings settings: [PBXFileReference: [String: String]]? = nil) -> PBXSourcesBuildPhase {
    let buildPhase = PBXSourcesBuildPhase()

    for ref in refs {
      if let ref = ref as? PBXFileReference {
        
        guard let fileUTI = ref.uti, fileUTI.hasPrefix("sourcecode.") && !fileUTI.hasSuffix(".h") else {
          continue
        }
        buildPhase.files.append(PBXBuildFile(fileRef: ref, settings: settings?[ref]))
      } else {
        buildPhase.files.append(PBXBuildFile(fileRef: ref))
      }

    }
    return buildPhase
  }

  
  private func createBuildTargetForRuleEntry(_ entry: RuleEntry,
                                             named name: String,
                                             ruleEntryMap: RuleEntryMap)
      throws -> (PBXNativeTarget) {
    guard let pbxTargetType = entry.pbxTargetType else {
      throw ProjectSerializationError.unsupportedTargetType(entry.type, entry.label.value)
    }
    let target = project.createNativeTarget(name,
                                            deploymentTarget: entry.deploymentTarget,
                                            targetType: pbxTargetType)

    for f in entry.secondaryArtifacts {
      project.createProductReference(f.fullPath)
    }

    var buildSettings = options.buildSettingsForTarget(name)
    buildSettings["TULSI_BUILD_PATH"] = entry.label.packageName!


    buildSettings["PRODUCT_NAME"] = name
    if let bundleID = entry.bundleID {
      buildSettings["PRODUCT_BUNDLE_IDENTIFIER"] = bundleID
    }
    if let sdkRoot = entry.XcodeSDKRoot {
      buildSettings["SDKROOT"] = sdkRoot
    }

    
    
    buildSettings["ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME"] = "Stub Launch Image"
    buildSettings["INFOPLIST_FILE"] = stubInfoPlistPaths.stubPlist(entry)

    if let deploymentTarget = entry.deploymentTarget {
      buildSettings[deploymentTarget.platform.buildSettingsDeploymentTarget] = deploymentTarget.osVersion
    }

    
    
    if pbxTargetType == .Watch1App {
      buildSettings["TARGETED_DEVICE_FAMILY"] = "4"
      buildSettings["TARGETED_DEVICE_FAMILY[sdk=iphonesimulator*]"] = "1,4"
    }

    
    
    
    if pbxTargetType == .AppClip {
      buildSettings["CODE_SIGNING_ALLOWED"] = "NO"
    }

    
    
    
    if let xcodeVersion = entry.xcodeVersion {
      buildSettings["TULSI_XCODE_VERSION"] = xcodeVersion
    }

    
    
    
    buildSettings["DEBUG_INFORMATION_FORMAT"] = "dwarf"

    
    buildSettings["BAZEL_TARGET"] = entry.label.value

    createBuildConfigurationsForList(target.buildConfigurationList, buildSettings: buildSettings)
    addTestRunnerBuildConfigurationToBuildConfigurationList(target.buildConfigurationList)

    if let buildPhase = createBuildPhaseForRuleEntry(entry) {
      target.buildPhases.append(buildPhase)
    }

    if let legacyTarget = bazelCleanScriptTarget {
      target.createDependencyOn(legacyTarget,
                                proxyType: PBXContainerItemProxy.ProxyType.targetReference,
                                inProject: project,
                                first: true)
    }

    return target
  }

  private func createGenerateSwiftDummyFilesTestBuildPhase() -> PBXShellScriptBuildPhase {
    let shellScript =
        "# Script to generate specific Swift files Xcode expects when running tests.\n" +
        "set -eu\n" +
        "ARCH_ARRAY=($ARCHS)\n" +
        "SUFFIXES=(swiftdoc swiftmodule)\n" +
        "for ARCH in \"${ARCH_ARRAY[@]}\"\n" +
        "do\n" +
        "  mkdir -p \"$OBJECT_FILE_DIR_normal/$ARCH/\"\n" +
        "  touch \"$OBJECT_FILE_DIR_normal/$ARCH/$SWIFT_OBJC_INTERFACE_HEADER_NAME\"\n" +
        "  for SUFFIX in \"${SUFFIXES[@]}\"\n" +
        "  do\n" +
        "    touch \"$OBJECT_FILE_DIR_normal/$ARCH/$PRODUCT_MODULE_NAME.$SUFFIX\"\n" +
        "  done\n" +
        "done\n"

    let buildPhase = PBXShellScriptBuildPhase(
      shellScript: shellScript,
      shellPath: "/bin/bash",
      name: "Swift dummy file generation")
    buildPhase.showEnvVarsInLog = true
    buildPhase.mnemonic = "SwiftDummy"
    return buildPhase
  }

  private func createGenerateDummyDependencyFilesTestBuildPhase(_ sources: [BazelFileInfo]) -> PBXShellScriptBuildPhase {
    let files = sources.map { ($0.subPath as NSString).deletingPathExtension.pbPathLastComponent }
    let shellScript = """
# Script to generate dependency files Xcode expects when running tests.
set -eu
ARCH_ARRAY=($ARCHS)
FILES=(\(files.map { $0.escapingForShell }.joined(separator: " ")))
for ARCH in "${ARCH_ARRAY[@]}"
do
  mkdir -p "$OBJECT_FILE_DIR_normal/$ARCH/"
  rm -f "$OBJECT_FILE_DIR_normal/$ARCH/${PRODUCT_NAME}_dependency_info.dat"
  printf '\\x00\\x31\\x00' >"$OBJECT_FILE_DIR_normal/$ARCH/${PRODUCT_NAME}_dependency_info.dat"
  for FILE in "${FILES[@]}"
  do
    touch "$OBJECT_FILE_DIR_normal/$ARCH/$FILE.d"
  done
done
"""
    let buildPhase = PBXShellScriptBuildPhase(
      shellScript: shellScript,
      shellPath: "/bin/bash",
      name: "Objective-C dummy file generation")
    buildPhase.showEnvVarsInLog = true
    buildPhase.mnemonic = "ObjcDummy"
    return buildPhase
  }

  private func createBuildPhaseForRuleEntry(_ entry: RuleEntry)
      -> PBXShellScriptBuildPhase? {
    let buildLabel = entry.label.value
    let commandLine = buildScriptCommandlineForBuildLabels(buildLabel)
    let workingDirectory = PBXTargetGenerator.workingDirectoryForPBXGroup(project.mainGroup)
    let changeDirectoryAction: String
    if workingDirectory.isEmpty {
      changeDirectoryAction = ""
    } else {
      changeDirectoryAction = "cd \"\(workingDirectory)\""
    }
    let shellScript = "set -e\n" +
        "\(changeDirectoryAction)\n" +
        "exec \(commandLine)"

    
    
    let inputPaths = ["$(TARGET_BUILD_DIR)/$(INFOPLIST_PATH)"]
    let buildPhase = PBXShellScriptBuildPhase(
      shellScript: shellScript,
      shellPath: "/bin/bash",
      name: "build \(entry.label)",
      inputPaths: inputPaths
    )
    buildPhase.showEnvVarsInLog = true
    buildPhase.mnemonic = "BazelBuild"
    return buildPhase
  }

  
  
  private func buildScriptCommandlineForBuildLabels(_ buildLabels: String) -> String {
    return "\"\(buildScriptPath)\" " +
        "\(buildLabels) " +
        "--bazel \"\(bazelPath)\" " +
        "--bazel_bin_path \"\(bazelBinPath)\" " +
        "--verbose "
  }
}
