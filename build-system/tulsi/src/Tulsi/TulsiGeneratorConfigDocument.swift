

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator


protocol TulsiGeneratorConfigDocumentDelegate: AnyObject {
  
  func didNameTulsiGeneratorConfigDocument(_ document: TulsiGeneratorConfigDocument, configName: String)

  
  func parentOptionSetForConfigDocument(_ document: TulsiGeneratorConfigDocument) -> TulsiOptionSet?
}



final class TulsiGeneratorConfigDocument: NSDocument,
                                          NSWindowDelegate,
                                          OptionsEditorModelProtocol,
                                          NewGeneratorConfigViewControllerDelegate,
                                          MessageLogProtocol {

  
  enum GenerationResult {
    
    case success(URL)
    
    case failure
  }

  
  
  static let FileType = "com.google.tulsi.generatorconfig"

  
  static let PerUserFileType = "com.google.tulsi.generatorconfig.user"

  weak var delegate: TulsiGeneratorConfigDocumentDelegate? = nil

  
  @objc dynamic var processing: Bool = false

  
  
  private var processingTaskCount: Int = 0 {
    didSet {
      assert(processingTaskCount >= 0, "Processing task count may never be negative")
      processing = processingTaskCount > 0
    }
  }

  
  @objc dynamic var outputFolderURL: URL? = nil

  
  
  
  var projectRuleInfos = [RuleInfo]() {
    didSet {
      let selectedEntryLabels = Set<String>(selectedUIRuleInfos.map({ $0.fullLabel }))
      var uiRuleInfoMap = [BuildLabel: UIRuleInfo]()
      var infosWithLinkages = [UIRuleInfo]()
      uiRuleInfos = projectRuleInfos.map() {
        let info = UIRuleInfo(ruleInfo: $0)
        info.selected = selectedEntryLabels.contains(info.fullLabel)
        uiRuleInfoMap[info.ruleInfo.label] = info
        if !info.ruleInfo.linkedTargetLabels.isEmpty {
          infosWithLinkages.append(info)
        }
        return info
      }

      for info in infosWithLinkages {
        info.resolveLinkages(uiRuleInfoMap)
      }
    }
  }

  private var uiRuleInfoObservers: [NSKeyValueObservation] = []

  
  @objc dynamic var uiRuleInfos = [UIRuleInfo]() {
    willSet {
      stopObservingRuleEntries()

      uiRuleInfoObservers = newValue.map { entry in
        entry.observe(
          \.selected, options: .new
        ) { [unowned self] _, change in
          guard let value = change.newValue else { return }
          if value {
            self.selectedRuleInfoCount += 1
          } else {
            self.selectedRuleInfoCount -= 1
          }
        }
      }
    }
  }

  
  var selectedUIRuleInfos: [UIRuleInfo] {
    return uiRuleInfos.filter { $0.selected }
  }

  private var selectedRuleInfos: [RuleInfo] {
    return selectedUIRuleInfos.map { $0.ruleInfo }
  }

  
  @objc dynamic var selectedRuleInfoCount: Int = 0 {
    didSet {
      updateChangeCount(.changeDone)
    }
  }

  
  var sourcePaths = [UISourcePath]()

  private var selectedSourcePaths: [UISourcePath] {
    return sourcePaths.filter { $0.selected || $0.recursive }
  }

  
  var configName: String? = nil {
    didSet {
      updateChangeCount(.changeDone)
    }
  }

  var messages: [UIMessage] {
    if let messageLog = messageLog {
      return messageLog.messages
    }
    return []
  }

  
  var bazelURL: URL? = nil
  var additionalFilePaths: [String]? = nil
  var saveFolderURL: URL! = nil
  var infoExtractor: TulsiProjectInfoExtractor! = nil
  var messageLog: MessageLogProtocol? = nil

  override var isEntireFileLoaded: Bool {
    return _entireFileLoaded
  }
  
  
  var _entireFileLoaded = true

  
  private var buildTargetLabels: [BuildLabel]? = nil

  
  private var saveCompletionHandler: ((_ canceled: Bool, _ error: Error?) -> Void)? = nil

  static func isGeneratorConfigFilename(_ filename: String) -> Bool {
    return (filename as NSString).pathExtension == TulsiGeneratorConfig.FileExtension
  }

  
  
  static func makeDocumentWithProjectRuleEntries(_ ruleInfos: [RuleInfo],
                                                 optionSet: TulsiOptionSet,
                                                 projectName: String,
                                                 saveFolderURL: URL,
                                                 infoExtractor: TulsiProjectInfoExtractor,
                                                 messageLog: MessageLogProtocol?,
                                                 additionalFilePaths: [String]? = nil,
                                                 bazelURL: URL? = nil,
                                                 name: String? = nil) throws -> TulsiGeneratorConfigDocument {
    let documentController = NSDocumentController.shared
    guard let doc = try documentController.makeUntitledDocument(ofType: TulsiGeneratorConfigDocument.FileType) as? TulsiGeneratorConfigDocument else {
      throw TulsiError(errorMessage: "Document for type \(TulsiGeneratorConfigDocument.FileType) was not the expected type.")
    }

    doc.projectRuleInfos = ruleInfos
    doc.additionalFilePaths = additionalFilePaths
    doc.projectName = projectName
    doc.saveFolderURL = saveFolderURL
    doc.infoExtractor = infoExtractor
    doc.messageLog = messageLog
    doc.bazelURL = bazelURL
    doc.configName = name

    documentController.addDocument(doc)

    LogMessage.postSyslog("Create config: \(projectName)", context: projectName)
    return doc
  }

  
  
  
  static func makeDocumentWithContentsOfURL(_ url: URL,
                                            infoExtractor: TulsiProjectInfoExtractor,
                                            messageLog: MessageLogProtocol?,
                                            bazelURL: URL? = nil,
                                            completionHandler: @escaping ((TulsiGeneratorConfigDocument) -> Void)) throws -> TulsiGeneratorConfigDocument {
    let doc = try makeSparseDocumentWithContentsOfURL(url,
                                                      infoExtractor: infoExtractor,
                                                      messageLog: messageLog,
                                                      bazelURL: bazelURL)
    doc.finishLoadingDocument(completionHandler)
    return doc
  }

  
  
  
  static func makeSparseDocumentWithContentsOfURL(_ url: URL,
                                                  infoExtractor: TulsiProjectInfoExtractor,
                                                  messageLog: MessageLogProtocol?,
                                                  bazelURL: URL? = nil) throws -> TulsiGeneratorConfigDocument {
    let documentController = NSDocumentController.shared
    guard let doc = try documentController.makeDocument(withContentsOf: url,
                                                                         ofType: TulsiGeneratorConfigDocument.FileType) as? TulsiGeneratorConfigDocument else {
      throw TulsiError(errorMessage: "Document for type \(TulsiGeneratorConfigDocument.FileType) was not the expected type.")
    }

    doc.infoExtractor = infoExtractor
    doc.messageLog = messageLog
    doc.bazelURL = bazelURL
    doc._entireFileLoaded = false
    return doc
  }

  static func urlForConfigNamed(_ name: String,
                                inFolderURL folderURL: URL?,
                                sanitized: Bool = true) -> URL? {
    let expectedFilename = "\(name).\(TulsiGeneratorConfig.FileExtension)"
    let filename: String
    if sanitized {
      filename = TulsiGeneratorConfig.sanitizeFilename(expectedFilename)
    } else {
      filename = expectedFilename
    }
    return folderURL?.appendingPathComponent(filename)
  }

  
  static func generateXcodeProjectInFolder(_ outputFolderURL: URL,
                                           withGeneratorConfig config: TulsiGeneratorConfig,
                                           workspaceRootURL: URL,
                                           messageLog: MessageLogProtocol?,
                                           projectInfoExtractor: TulsiProjectInfoExtractor? = nil) -> GenerationResult {

    let tulsiVersion: String
    if let cfBundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      tulsiVersion = cfBundleVersion
    } else {
      tulsiVersion = ""
    }
    let projectGenerator = TulsiXcodeProjectGenerator(workspaceRootURL: workspaceRootURL,
                                                      config: config,
                                                      tulsiVersion: tulsiVersion)
    let errorInfo: String
    let startTime = Date()

    do {
      let url = try projectGenerator.generateXcodeProjectInFolder(outputFolderURL)
      let timeTaken = String(format: "%.4fs", Date().timeIntervalSince(startTime))
      LogMessage.postSyslog("Generate[OK]: \(timeTaken)", context: config.projectName)
      return .success(url)
    } catch TulsiXcodeProjectGenerator.GeneratorError.unsupportedTargetType(let targetType,
                                                                            let label) {
      errorInfo = "Unsupported target type: \(targetType) (target \(label))"
    } catch TulsiXcodeProjectGenerator.GeneratorError.serializationFailed(let details) {
      errorInfo = "General failure: \(details)"
    } catch _ {
      errorInfo = "Unexpected failure"
    }
    let timeTaken = String(format: "%.4fs", Date().timeIntervalSince(startTime))
    LogMessage.postError("Generate[FAIL]: \(timeTaken)",
                         details: errorInfo,
                         context: config.projectName)
    return .failure
  }

  deinit {
    NSObject.unbind(NSBindingName(rawValue: "projectRuleEntries"))
    stopObservingRuleEntries()
    assert(saveCompletionHandler == nil)
  }

  
  func save(completionHandler: @escaping ((Bool, Error?) -> Void)) {
    assert(saveCompletionHandler == nil)
    saveCompletionHandler = completionHandler
    self.save(nil)
  }

  func revert() throws {
    guard let url = fileURL else { return }
    try self.revert(toContentsOf: url, ofType: TulsiGeneratorConfigDocument.FileType)
  }

  override func makeWindowControllers() {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let windowController = storyboard.instantiateController(withIdentifier: "TulsiGeneratorConfigDocumentWindow") as! NSWindowController
    windowController.contentViewController?.representedObject = self
    windowController.window?.isRestorable = false
    addWindowController(windowController)
  }

  
  func headlessSave(_ configName: String) {
    
    do {
      try FileManager.default.createDirectory(at: saveFolderURL,
                                                              withIntermediateDirectories: true,
                                                              attributes: nil)
    } catch let e as NSError {
      if let completionHandler = saveCompletionHandler {
        completionHandler(false, e)
        saveCompletionHandler = nil
      }
      return
    }

    guard let targetURL = TulsiGeneratorConfigDocument.urlForConfigNamed(configName,
                                                                         inFolderURL: saveFolderURL) else {
      if let completionHandler = saveCompletionHandler {
        completionHandler(false, TulsiError(code: .configNotSaveable))
        saveCompletionHandler = nil
      }
      return
    }

    self.save(to: targetURL,
              ofType: TulsiGeneratorConfigDocument.FileType,
              for: .saveOperation) { (error: Error?) in
      
    }
  }

  override func save(to url: URL,
                     ofType typeName: String,
                     for saveOperation: NSDocument.SaveOperationType,
                     completionHandler: @escaping (Error?) -> Void) {
    var writeError: NSError? = nil
    do {
      
      try write(to: url, ofType: typeName, for: saveOperation, originalContentsURL: nil)
    } catch let error as NSError {
      let fmt = NSLocalizedString("Error_ConfigSaveFailed",
                                  comment: "Error when a TulsiGeneratorConfig failed to save. Details are provided as %1$@.")
      LogMessage.postWarning(String(format: fmt, error.localizedDescription))

      let alert = NSAlert(error: error)
      alert.runModal()

      writeError = error
    }
    completionHandler(writeError)

    if let concreteCompletionHandler = self.saveCompletionHandler {
      concreteCompletionHandler(false, writeError)
      self.saveCompletionHandler = nil
    }

    if writeError == nil {
      let configName = (url.lastPathComponent as NSString).deletingPathExtension
      self.delegate?.didNameTulsiGeneratorConfigDocument(self, configName: configName)
    }
  }

  override func data(ofType typeName: String) throws -> Data {
    guard let config = makeConfig() else {
      throw TulsiError(code: .configNotSaveable)
    }
    switch typeName {
    case TulsiGeneratorConfigDocument.FileType:
      return try config.save() as Data
    case TulsiGeneratorConfigDocument.PerUserFileType:
      if let userSettings = try config.savePerUserSettings() {
        return userSettings as Data
      }
      return Data()
    default:
      throw NSError(domain: NSCocoaErrorDomain, code: NSFeatureUnsupportedError, userInfo: nil)
    }
  }

  override func read(from url: URL, ofType typeName: String) throws {
    let filename = url.lastPathComponent
    configName = (filename as NSString).deletingPathExtension
    let config = try TulsiGeneratorConfig.load(url)

    projectName = config.projectName
    buildTargetLabels = config.buildTargetLabels
    additionalFilePaths = config.additionalFilePaths
    optionSet = config.options
    bazelURL = config.bazelURL

    sourcePaths = []
    for sourceFilter in config.pathFilters {
      let sourcePath: UISourcePath
      if sourceFilter.hasSuffix("/...") {
        let targetIndex = sourceFilter.index(sourceFilter.endIndex, offsetBy: -4)
        let path = String(sourceFilter[..<targetIndex])
        sourcePath = UISourcePath(path: path, selected: false, recursive: true)
      } else {
        sourcePath = UISourcePath(path: sourceFilter, selected: true, recursive: false)
      }
      sourcePaths.append(sourcePath)
    }
  }

  override class var autosavesInPlace: Bool {
    return false
  }

  override func prepareSavePanel(_ panel: NSSavePanel) -> Bool {
    
    assertionFailure("Save panel should never be invoked.")
    return false
  }

  private func enabledFeatures(options: TulsiOptionSet) -> Set<BazelSettingFeature> {
    return BazelBuildSettingsFeatures.enabledFeatures(options: options)
  }

  
  func updateSourcePaths(_ callback: @escaping ([UISourcePath]) -> Void) {
    var sourcePathMap = [String: UISourcePath]()
    selectedSourcePaths.forEach() { sourcePathMap[$0.path] = $0 }
    processingTaskStarted()

    let selectedLabels = self.selectedRuleInfos.map() { $0.label }
    let optionSet = self.optionSet!
    Thread.doOnQOSUserInitiatedThread() {
      defer {
        Thread.doOnMainQueue() {
          self.sourcePaths = [UISourcePath](sourcePathMap.values)
          callback(self.sourcePaths)
          self.processingTaskFinished()
        }
      }
      let ruleEntryMap: RuleEntryMap
      do {
        let startupOptions = optionSet[.BazelBuildStartupOptionsDebug]
        let extraStartupOptions = optionSet[.ProjectGenerationBazelStartupOptions]
        let buildOptions = optionSet[.BazelBuildOptionsDebug]
        let compilationModeOption = optionSet[.ProjectGenerationCompilationMode]
        let platformConfigOption = optionSet[.ProjectGenerationPlatformConfiguration]
        let prioritizeSwiftOption = optionSet[.ProjectPrioritizesSwift]
        let use64BitWatchSimulatorOption = optionSet[.Use64BitWatchSimulator]
        ruleEntryMap = try self.infoExtractor.ruleEntriesForLabels(selectedLabels,
                                                                   startupOptions: startupOptions,
                                                                   extraStartupOptions: extraStartupOptions,
                                                                   buildOptions: buildOptions,
                                                                   compilationModeOption: compilationModeOption,
                                                                   platformConfigOption: platformConfigOption,
                                                                   prioritizeSwiftOption: prioritizeSwiftOption,
                                                                   use64BitWatchSimulatorOption: use64BitWatchSimulatorOption,
                                                                   features: self.enabledFeatures(options: optionSet))
      } catch TulsiProjectInfoExtractor.ExtractorError.ruleEntriesFailed(let info) {
        LogMessage.postError("Label resolution failed: \(info)")
        return
      } catch let e {
        LogMessage.postError("Label resolution failed. \(e)")
        return
      }

      var unresolvedLabels = Set<BuildLabel>()
      var sourceRuleEntries = [RuleEntry]()
      for label in selectedLabels {
        let ruleEntries = ruleEntryMap.ruleEntries(buildLabel: label)
        if ruleEntries.isEmpty {
          unresolvedLabels.insert(label)
        } else {
          sourceRuleEntries.append(contentsOf: ruleEntries)
        }
      }

      if !unresolvedLabels.isEmpty {
        let fmt = NSLocalizedString("Warning_LabelResolutionFailed",
                                    comment: "A non-critical failure to restore some Bazel labels when loading a document. Details are provided as %1$@.")
        LogMessage.postWarning(String(format: fmt,
                                      "Missing labels: \(unresolvedLabels.map({$0.description}))"))
      }

      var selectedRuleEntries = [RuleEntry]()
      for selectedRuleInfo in self.selectedRuleInfos {
        selectedRuleEntries.append(contentsOf: ruleEntryMap.ruleEntries(buildLabel: selectedRuleInfo.label))
      }

      var processedEntries = Set<RuleEntry>()

      let componentDelimiters = CharacterSet(charactersIn: "/:")
      func addPath(_ path: String) {
        let path = (path as NSString).deletingLastPathComponent
        if path.isEmpty { return }

        let pathComponents = path.components(separatedBy: componentDelimiters)
        var cumulativePathComponents = [String]()
        for component in pathComponents {
          cumulativePathComponents.append(component)
          let componentPath = cumulativePathComponents.joined(separator: "/")
          cumulativePathComponents = [componentPath]
          if sourcePathMap[componentPath] == nil {
            sourcePathMap[componentPath] = UISourcePath(path: componentPath)
          }
        }
      }

      func extractSourcePaths(_ ruleEntry: RuleEntry) {
        if processedEntries.contains(ruleEntry) {
          
          
          return
        }
        processedEntries.insert(ruleEntry)
        for dep in ruleEntry.dependencies {
          guard let depRuleEntry = ruleEntryMap.ruleEntry(buildLabel: dep, depender: ruleEntry) else {
            
            
            continue
          }
          extractSourcePaths(depRuleEntry)
        }

        for fileInfo in ruleEntry.projectArtifacts {
          addPath(fileInfo.fullPath)
        }
      }

      var sourceTargets = [BuildLabel]()
      for entry in sourceRuleEntries {
        extractSourcePaths(entry)
        sourceTargets.append(entry.label)
      }

      let buildfiles = self.infoExtractor.extractBuildfiles(sourceTargets)
      for buildfileLabel in buildfiles {
        guard let path = buildfileLabel.asFileName else { continue }
        addPath(path)
      }
    }
  }

  @IBAction override func save(_ sender: Any?) {
    if fileURL != nil {
      super.save(sender)
      return
    }
    saveAs(sender)
  }

  @IBAction override func saveAs(_ sender: Any?) {
    let newConfigSheet = NewGeneratorConfigViewController()
    newConfigSheet.configName = configName
    newConfigSheet.delegate = self
    windowForSheet?.contentViewController?.presentAsSheet(newConfigSheet)
  }

  
  func generateXcodeProjectInFolder(_ outputFolderURL: URL,
                                    withWorkspaceRootURL workspaceRootURL: URL) -> URL? {
    assert(!Thread.isMainThread, "Must not be called from the main thread")

    guard let config = makeConfig(withFullyResolvedOptions: true) else {
      let msg = NSLocalizedString("Error_GeneralProjectGenerationFailure",
                                  comment: "A general, critical failure during project generation.")
      LogMessage.postError(msg, details: "Generator config is not fully populated.")
      LogMessage.displayPendingErrors()
      return nil
    }

    let result = TulsiGeneratorConfigDocument.generateXcodeProjectInFolder(outputFolderURL,
                                                                           withGeneratorConfig: config,
                                                                           workspaceRootURL: workspaceRootURL,
                                                                           messageLog: self,
                                                                           projectInfoExtractor: infoExtractor)
    switch result {
      case .success(let url):
        return url
      case .failure:
        let msg = NSLocalizedString("Error_GeneralProjectGenerationFailure",
                                    comment: "A general, critical failure during project generation.")
        LogMessage.postError(msg)
        LogMessage.displayPendingErrors()
        return nil
    }
  }

  
  
  
  func finishLoadingDocument(_ completionHandler: @escaping ((TulsiGeneratorConfigDocument) -> Void)) {
    processingTaskStarted()
    Thread.doOnQOSUserInitiatedThread() {
      defer {
        self.processingTaskFinished()
        self._entireFileLoaded = true
        completionHandler(self)
      }
      do {
        
        try self.resolveLabelReferences() {
          if let concreteBuildTargetLabels = self.buildTargetLabels {
            let fmt = NSLocalizedString("Warning_LabelResolutionFailed",
                                        comment: "A non-critical failure to restore some Bazel labels when loading a document. Details are provided as %1$@.")
            LogMessage.postWarning(String(format: fmt,
                                          concreteBuildTargetLabels.map({ $0.description })))
          }
        }
      } catch TulsiProjectInfoExtractor.ExtractorError.ruleEntriesFailed(let info) {
        LogMessage.postError("Label resolution failed: \(info)")
      } catch let e {
        LogMessage.postError("Label resolution failed. \(e)")
      }
    }
  }

  func addProcessingTaskCount(_ taskCount: Int) {
    Thread.doOnMainQueue() { self.processingTaskCount += taskCount }
  }

  func processingTaskStarted() {
    Thread.doOnMainQueue() { self.processingTaskCount += 1 }
  }

  func processingTaskFinished() {
    Thread.doOnMainQueue() { self.processingTaskCount -= 1 }
  }

  

  func windowWillClose(_ notification: Notification) {
    stopObservingRuleEntries()
  }

  

  var projectName: String? = nil

  var optionSet: TulsiOptionSet? = TulsiOptionSet(withInheritanceEnabled: true)

  var projectValueColumnTitle: String {
    return NSLocalizedString("OptionsEditor_ColumnTitle_Config",
                             comment: "Title for the options editor column used to edit per-config values.")
  }

  var defaultValueColumnTitle: String {
    return NSLocalizedString("OptionsEditor_ColumnTitle_Project",
                             comment: "Title for the options editor column used to edit per-tulsiproj values.")
  }

  var optionsTargetUIRuleEntries: [UIRuleInfo]? {
    return selectedUIRuleInfos
  }

  func parentOptionForOptionKey(_ key: TulsiOptionKey) -> TulsiOption? {
    
    guard let parentOptionSet = delegate?.parentOptionSetForConfigDocument(self) else { return nil }
    return parentOptionSet[key]
  }

  

  override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    let itemAction = item.action
    switch itemAction {
      case .some(#selector(TulsiGeneratorConfigDocument.self.save(_:))):
        return true

      case .some(#selector(TulsiGeneratorConfigDocument.saveAs(_:))):
        return windowForSheet?.contentViewController != nil

      
      case .some(#selector(TulsiGeneratorConfigDocument.duplicate(_:))):
        return false
      case .some(#selector(TulsiGeneratorConfigDocument.rename(_:))):
        return false
      case .some(#selector(TulsiGeneratorConfigDocument.move(_:))):
        return false

      default:
        Swift.print("Unhandled menu action: \(String(describing: itemAction))")
    }
    return false
  }

  

  func viewController(_ vc: NewGeneratorConfigViewController,
                      didCompleteWithReason reason: NewGeneratorConfigViewController.CompletionReason) {
    windowForSheet?.contentViewController?.dismiss(vc)
    guard reason == .create else {
      if let completionHandler = saveCompletionHandler {
        completionHandler(true, nil)
        saveCompletionHandler = nil
      }
      return
    }

    headlessSave(vc.configName!)
  }

  

  private func stopObservingRuleEntries() {
    uiRuleInfoObservers.forEach { $0.invalidate() }
    uiRuleInfoObservers = []
  }

  private func makeConfig(withFullyResolvedOptions resolve: Bool = false) -> TulsiGeneratorConfig? {
    guard let concreteProjectName = projectName,
              let concreteOptionSet = optionSet else {
      return nil
    }

    let configOptions: TulsiOptionSet
    if resolve {
      guard let resolvedOptionSet = resolveOptionSet() else {
        assertionFailure("Failed to resolve option set.")
        return nil
      }
      configOptions = resolvedOptionSet
    } else {
      configOptions = concreteOptionSet
    }

    let pathFilters = Set<String>(selectedSourcePaths.map() {
      if $0.recursive {
        return $0.path + "/..."
      }
      return $0.path
    })

    guard let bazelURL = TulsiGeneratorConfig.resolveBazelURL(bazelURL,
                                                              options: configOptions) else {
      let msg = NSLocalizedString("Error_ResolveBazelPathFailure",
                                  comment: "Error when unable to locate Bazel.")
      LogMessage.postError(msg, details: "Generator config needs a bazelURL.")
      return nil
    }

    
    if isEntireFileLoaded {
      return TulsiGeneratorConfig(projectName: concreteProjectName,
                                  buildTargets: selectedRuleInfos,
                                  pathFilters: pathFilters,
                                  additionalFilePaths: additionalFilePaths,
                                  options: configOptions,
                                  bazelURL: bazelURL)
    } else {
      return TulsiGeneratorConfig(projectName: concreteProjectName,
                                  buildTargetLabels: buildTargetLabels ?? [],
                                  pathFilters: pathFilters,
                                  additionalFilePaths: additionalFilePaths,
                                  options: configOptions,
                                  bazelURL: bazelURL)
    }
  }

  private func resolveOptionSet() -> TulsiOptionSet? {
    guard let configOptionSet = optionSet else { return nil }
    guard let parentOptionSet = delegate?.parentOptionSetForConfigDocument(self) else {
      return configOptionSet
    }
    return configOptionSet.optionSetByInheritingFrom(parentOptionSet)
  }

  
  
  private func resolveLabelReferences(_ completionHandler: @escaping (() -> Void)) throws {
    guard let concreteBuildTargetLabels = buildTargetLabels, !concreteBuildTargetLabels.isEmpty else {
      buildTargetLabels = nil
      Thread.doOnMainQueue() {
        completionHandler()
      }
      return
    }

    let options = optionSet!
    let ruleEntryMap = try infoExtractor.ruleEntriesForLabels(concreteBuildTargetLabels,
                                                              startupOptions: options[.BazelBuildStartupOptionsDebug],
                                                              extraStartupOptions: options[.ProjectGenerationBazelStartupOptions],
                                                              buildOptions: options[.BazelBuildOptionsDebug],
                                                              compilationModeOption: options[.ProjectGenerationCompilationMode],
                                                              platformConfigOption: options[.ProjectGenerationPlatformConfiguration],
                                                              prioritizeSwiftOption: options[.ProjectPrioritizesSwift],
                                                              use64BitWatchSimulatorOption: options[.Use64BitWatchSimulator],
                                                              features: enabledFeatures(options: options))
    var unresolvedLabels = Set<BuildLabel>()
    var ruleInfos = [UIRuleInfo]()
    for label in concreteBuildTargetLabels {
      let ruleEntries = ruleEntryMap.ruleEntries(buildLabel: label)
      guard let info = ruleEntries.last else {
        unresolvedLabels.insert(label)
        continue
      }
      if ruleEntries.count > 1 {
        let fmt = NSLocalizedString("AmbiguousBuildTarget",
                                    comment: "Multiple deployment targets found for RuleEntry. Label is in %1$@. Type is in %2$@.")
        LogMessage.postWarning(String(format: fmt, label.description, info.type))
      }

      let uiRuleEntry = UIRuleInfo(ruleInfo: info)
      uiRuleEntry.selected = true
      ruleInfos.append(uiRuleEntry)
    }

    
    let existingInfos = self.uiRuleInfos.filter() {
      !concreteBuildTargetLabels.contains($0.ruleInfo.label)
    }

    Thread.doOnMainQueue() {
      for existingInfo in existingInfos {
        existingInfo.selected = false
        ruleInfos.append(existingInfo)
      }
      self.uiRuleInfos = ruleInfos
      self.buildTargetLabels = unresolvedLabels.isEmpty ? nil : [BuildLabel](unresolvedLabels)
      self.selectedRuleInfoCount = self.selectedRuleInfos.count
      completionHandler()
    }
  }
}
