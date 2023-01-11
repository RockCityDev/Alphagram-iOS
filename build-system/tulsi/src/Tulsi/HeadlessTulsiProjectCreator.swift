

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



struct HeadlessTulsiProjectCreator {

  let arguments: TulsiCommandlineParser.Arguments

  init(arguments: TulsiCommandlineParser.Arguments) {
    self.arguments = arguments
  }

  
  func generate() throws {
    guard let bazelPath = arguments.bazel else {
      throw HeadlessModeError.missingBazelPath
    }
    let defaultFileManager = FileManager.default
    if !defaultFileManager.isExecutableFile(atPath: bazelPath) {
      throw HeadlessModeError.invalidBazelPath
    }

    guard let tulsiprojName = arguments.tulsiprojName else {
      fatalError("HeadlessTulsiProjectCreator invoked without a valid tulsiprojName")
    }

    guard let targets = arguments.buildTargets else {
      throw HeadlessModeError.missingBuildTargets
    }

    guard let outputFolderPath = arguments.outputFolder else {
      throw HeadlessModeError.explicitOutputOptionRequired
    }

    let (projectURL, projectName) = try buildOutputPath(outputFolderPath,
                                                        projectBundleName: tulsiprojName)

    let workspaceRootURL: URL
    if let explicitWorkspaceRoot = arguments.workspaceRootOverride {
      workspaceRootURL = URL(fileURLWithPath: explicitWorkspaceRoot, isDirectory: true)
    } else {
      workspaceRootURL = URL(fileURLWithPath: defaultFileManager.currentDirectoryPath,
                               isDirectory: true)
    }
    let workspaceFileURL = try buildWORKSPACEFileURL(workspaceRootURL)

    TulsiProjectDocument.showAlertsOnErrors = false
    defer {
      TulsiProjectDocument.showAlertsOnErrors = true
    }

    try createTulsiProject(projectName,
                           workspaceFileURL: workspaceFileURL,
                           targets: targets,
                           atURL: projectURL)
  }

  

  private func createTulsiProject(_ projectName: String,
                                  workspaceFileURL: URL,
                                  targets: [String],
                                  atURL projectURL: URL) throws {
    let document = TulsiProjectDocument()
    document.createNewProject(projectName, workspaceFileURL: workspaceFileURL)

    let bazelPackages = processBazelPackages(document, targets: targets)

    if document.ruleInfos.isEmpty {
      throw HeadlessModeError.bazelTargetProcessingFailed
    }

    if let buildStartupOptions = arguments.buildStartupOptions {
      guard let optionSet = document.optionSet else {
        fatalError("Failed to retrieve option set.")
      }
      optionSet[.BazelBuildStartupOptionsDebug].projectValue = buildStartupOptions
      optionSet[.BazelBuildStartupOptionsRelease].projectValue = buildStartupOptions
    }
    if let buildOptions = arguments.buildOptions {
      guard let optionSet = document.optionSet else {
        fatalError("Failed to retrieve option set.")
      }
      optionSet[.BazelBuildOptionsDebug].projectValue = buildOptions
      optionSet[.BazelBuildOptionsRelease].projectValue = buildOptions
    }

    document.fileURL = projectURL


    try document.writeSafely(to: projectURL,
                             ofType: "com.google.tulsi.project",
                             for: .saveOperation)

    try addDefaultConfig(document,
                         named: projectName,
                         bazelPackages: bazelPackages,
                         targets: targets,
                         additionalSourcePaths: arguments.additionalPathFilters)
  }

  private func processBazelPackages(_ document: TulsiProjectDocument,
                                    targets: [String]) -> Set<String> {
    let bazelPackages = extractBazelPackages(targets)

    
    
    let semaphore = DispatchSemaphore(value: 0)
    let observer = document.observe(\.processing, options: .new) { _, change in
      guard change.newValue == false else { return }
      semaphore.signal()
    }
    defer { observer.invalidate() }
    document.bazelPackages = Array(bazelPackages)

    
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)

    return bazelPackages
  }

  private func addDefaultConfig(_ projectDocument: TulsiProjectDocument,
                                named projectName: String,
                                bazelPackages: Set<String>,
                                targets: [String],
                                additionalSourcePaths: Set<String>? = nil) throws {
    let additionalFilePaths = bazelPackages.map() { "\($0)/BUILD" }
    guard let generatorConfigFolderURL = projectDocument.generatorConfigFolderURL else {
      fatalError("Config folder unexpectedly nil")
    }

    let configDocument = try TulsiGeneratorConfigDocument.makeDocumentWithProjectRuleEntries(projectDocument.ruleInfos,
                                                                                             optionSet: projectDocument.optionSet!,
                                                                                             projectName: projectName,
                                                                                             saveFolderURL: generatorConfigFolderURL,
                                                                                             infoExtractor: projectDocument.infoExtractor,
                                                                                             messageLog: projectDocument,
                                                                                             additionalFilePaths: additionalFilePaths,
                                                                                             bazelURL: projectDocument.bazelURL)
    projectDocument.trackChildConfigDocument(configDocument)

    let targetLabels = Set(targets.map() { BuildLabel($0, normalize: true) })
    
    for info in configDocument.uiRuleInfos {
      info.selected = targetLabels.contains(info.ruleInfo.label)
    }

    
    configDocument.sourcePaths = [UISourcePath(path: ".", selected: true, recursive: true)]
    if let sourcePaths = additionalSourcePaths {
        
        
        configDocument.sourcePaths += sourcePaths.map { UISourcePath(path: $0, selected: false, recursive: true) }
    }
    configDocument.headlessSave(projectName)
  }

  private func extractBazelPackages(_ targets: [String]) -> Set<String> {
    var buildFiles = Set<String>()
    for target in targets {
      guard let range = target.range(of: ":"), !range.isEmpty else { continue }
      let package = String(target[..<range.lowerBound])
      buildFiles.insert(package)
    }
    return buildFiles
  }

  /// Processes the "outputFolder" argument, returning the Tulsi project bundle URL and project
  
  private func buildOutputPath(_ outputFolderPath: String,
                               projectBundleName: String) throws -> (URL, String) {
    let outputFolderURL = URL(fileURLWithPath: outputFolderPath, isDirectory: true)

    guard projectBundleName == (projectBundleName as NSString).lastPathComponent else {
      throw HeadlessModeError.invalidProjectBundleName
    }

    let projectName = (projectBundleName as NSString).deletingPathExtension
    let normalizedProjectBundleName = "\(projectName).\(TulsiProjectDocument.getTulsiBundleExtension())"


    let projectBundleURL = outputFolderURL.appendingPathComponent(normalizedProjectBundleName,
                                                                       isDirectory: false)

    return (projectBundleURL, projectName)
  }

  private func buildWORKSPACEFileURL(_ workspaceRootURL: URL) throws -> URL {

    let workspaceFile = workspaceRootURL.appendingPathComponent("WORKSPACE", isDirectory: false)

    var isDirectory = ObjCBool(false)
    if !FileManager.default.fileExists(atPath: workspaceFile.path,
                                       isDirectory: &isDirectory) || isDirectory.boolValue {
      throw HeadlessModeError.missingWORKSPACEFile(workspaceRootURL.path)
    }
    return workspaceFile
  }
}
