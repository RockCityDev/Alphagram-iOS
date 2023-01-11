

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

public enum XcodeActionType: String {
    case BuildAction,
         LaunchAction,
         TestAction
}


final class XcodeScheme {

  typealias BuildActionEntryAttributes = [String: String]
  enum LaunchStyle: String {
    case Normal = "0"
    case AppExtension = "2"
  }

  enum RunnableDebuggingMode: String {
    case Default = "0"
    case Remote = "2"
  }

  let version: String
  
  let target: PBXTarget?
  let primaryTargetBuildableReference: BuildableReference?

  let project: PBXProject
  let projectBundleName: String
  let testActionBuildConfig: String
  let launchActionBuildConfig: String
  let profileActionBuildConfig: String
  let analyzeActionBuildConfig: String
  let archiveActionBuildConfig: String
  let appExtension: Bool
  let extensionType: String?
  let customLLDBInitFile: String?
  let launchStyle: LaunchStyle?
  let runnableDebuggingMode: RunnableDebuggingMode
  let explicitTests: [PBXTarget]?
  
  
  let additionalBuildTargets: [(PBXTarget, String, BuildActionEntryAttributes)]?

  let commandlineArguments: [String]
  let environmentVariables: [String: String]
  let preActionScripts: [XcodeActionType: String]
  let postActionScripts: [XcodeActionType: String]
  let localizedMessageLogger: LocalizedMessageLogger

  init(target: PBXTarget?,
       project: PBXProject,
       projectBundleName: String,
       testActionBuildConfig: String = "Debug",
       launchActionBuildConfig: String = "Debug",
       profileActionBuildConfig: String = "Release",
       analyzeActionBuildConfig: String = "Debug",
       archiveActionBuildConfig: String = "Release",
       appExtension: Bool = false,
       extensionType: String? = nil,
       customLLDBInitFile: String? = nil,
       launchStyle: LaunchStyle? = nil,
       runnableDebuggingMode: RunnableDebuggingMode = .Default,
       version: String = "1.3",
       explicitTests: [PBXTarget]? = nil,
       additionalBuildTargets: [(PBXTarget, String, BuildActionEntryAttributes)]? = nil,
       commandlineArguments: [String] = [],
       environmentVariables: [String: String] = [:],
       preActionScripts: [XcodeActionType: String],
       postActionScripts: [XcodeActionType: String],
       localizedMessageLogger: LocalizedMessageLogger) {
    self.version = version
    self.project = project
    self.projectBundleName = projectBundleName
    self.testActionBuildConfig = testActionBuildConfig
    self.launchActionBuildConfig = launchActionBuildConfig
    self.profileActionBuildConfig = profileActionBuildConfig
    self.analyzeActionBuildConfig = analyzeActionBuildConfig
    self.archiveActionBuildConfig = archiveActionBuildConfig
    self.appExtension = appExtension
    self.extensionType = extensionType
    self.customLLDBInitFile = customLLDBInitFile
    self.launchStyle = launchStyle
    self.runnableDebuggingMode = runnableDebuggingMode
    self.explicitTests = explicitTests
    self.additionalBuildTargets = additionalBuildTargets

    self.commandlineArguments = commandlineArguments
    self.environmentVariables = environmentVariables

    self.preActionScripts = preActionScripts
    self.postActionScripts = postActionScripts

    self.localizedMessageLogger = localizedMessageLogger

    if let target = target {
      self.target = target
      primaryTargetBuildableReference = BuildableReference(target: target,
                                                           projectBundleName: projectBundleName)
    } else {
      self.target = nil
      primaryTargetBuildableReference = nil
    }
  }

  func toXML() -> XMLDocument {
    let rootElement = XMLElement(name: "Scheme")
    var rootAttributes = [
        "version": version,
        "LastUpgradeVersion": project.lastUpgradeCheck
    ]
    if appExtension {
      rootAttributes["wasCreatedForAppExtension"] = "YES"
    }
    rootElement.setAttributesWith(rootAttributes)

    rootElement.addChild(buildAction())
    rootElement.addChild(testAction())
    rootElement.addChild(launchAction())
    rootElement.addChild(profileAction())
    rootElement.addChild(analyzeAction())
    rootElement.addChild(archiveAction())

    return XMLDocument(rootElement: rootElement)
  }

  

  /// Settings for the Xcode "Build" action.
  private func buildAction() -> XMLElement {
    let element = XMLElement(name: "BuildAction")
    let parallelizeBuildables: String
    if runnableDebuggingMode == .Remote {
      parallelizeBuildables = "NO"
    } else {
      parallelizeBuildables = "YES"
    }
    let buildActionAttributes = [
        "parallelizeBuildables": parallelizeBuildables,
        "buildImplicitDependencies": "YES",
    ]
    element.setAttributesWith(buildActionAttributes)

    let buildActionEntries = XMLElement(name: "BuildActionEntries")

    func addBuildActionEntry(_ buildableReference: BuildableReference,
                             buildActionEntryAttributes: BuildActionEntryAttributes) {
      let buildActionEntry = XMLElement(name: "BuildActionEntry")
      buildActionEntry.setAttributesWith(buildActionEntryAttributes)
      buildActionEntry.addChild(buildableReference.toXML())
      buildActionEntries.addChild(buildActionEntry)
    }

    if let primaryTargetBuildableReference = primaryTargetBuildableReference {
      let primaryTargetEntryAttributes = XcodeScheme.makeBuildActionEntryAttributes()
      addBuildActionEntry(primaryTargetBuildableReference,
                          buildActionEntryAttributes: primaryTargetEntryAttributes)
    }
    if let additionalBuildTargets = additionalBuildTargets {
      for (target, bundleName, entryAttributes) in additionalBuildTargets {
        let buildableReference = BuildableReference(target: target, projectBundleName: bundleName)
        addBuildActionEntry(buildableReference, buildActionEntryAttributes: entryAttributes)
      }
    }

    element.addChild(buildActionEntries)
    if let preActionScript = preActionScripts[XcodeActionType.BuildAction] {
        element.addChild(preActionElement(preActionScript))
    }
    if let postActionScript = postActionScripts[XcodeActionType.BuildAction] {
        element.addChild(postActionElement(postActionScript))
    }
    return element
  }

  /// Settings for the Xcode "Test" action.
  private func testAction() -> XMLElement {
    let element = XMLElement(name: "TestAction")
    var testActionAttributes = [
      "buildConfiguration": testActionBuildConfig,
      "selectedDebuggerIdentifier": "Xcode.DebuggerFoundation.Debugger.LLDB",
      "selectedLauncherIdentifier": "Xcode.DebuggerFoundation.Launcher.LLDB",
      "shouldUseLaunchSchemeArgsEnv": "YES",
    ]
    if let customLLDBInitFile = self.customLLDBInitFile {
      testActionAttributes["customLLDBInitFile"] = customLLDBInitFile
    }
    element.setAttributesWith(testActionAttributes)

    let testTargets: [PBXTarget]
    if let explicitTests = explicitTests {
      testTargets = explicitTests
    } else {

      
      
      let linkedTestTargets: [PBXTarget]
      if let target = target {
        linkedTestTargets = project.linkedTestTargetsForHost(target)
      } else {
        linkedTestTargets = []
      }
      if linkedTestTargets.isEmpty {
        if let nativeTarget = target as? PBXNativeTarget,
           nativeTarget.productType.isTest {
          testTargets = [nativeTarget]
        } else {
          testTargets = []
        }
      } else {
        testTargets = linkedTestTargets
      }
    }

    let testables = XMLElement(name: "Testables")
    for testTarget in testTargets {
      let testableReference = XMLElement(name: "TestableReference")
      testableReference.setAttributesWith(["skipped": "NO"])

      let buildableRef = BuildableReference(target: testTarget,
                                            projectBundleName: projectBundleName)
      testableReference.addChild(buildableRef.toXML())
      testables.addChild(testableReference)
    }

    element.addChild(testables)
    if let preActionScript = preActionScripts[XcodeActionType.TestAction] {
      element.addChild(preActionElement(preActionScript))
    }
    if let postActionScript = postActionScripts[XcodeActionType.TestAction] {
        element.addChild(postActionElement(postActionScript))
    }

    
    
    if explicitTests == nil {
      if let runnable = buildableProductRunnable(runnableDebuggingMode) {
        element.addChild(runnable)
      }
    } else {
      if let reference = macroReference() {
        element.addChild(reference)
      }
    }
    return element
  }

  /// Settings for the Xcode "Run" action.
  private func launchAction() -> XMLElement {
    let element = XMLElement(name: "LaunchAction")
    var attributes = [
        "buildConfiguration": launchActionBuildConfig,
        "selectedDebuggerIdentifier": "Xcode.DebuggerFoundation.Debugger.LLDB",
        "selectedLauncherIdentifier": "Xcode.DebuggerFoundation.Launcher.LLDB",
        "launchStyle": "0",
        "useCustomWorkingDirectory": "NO",
        "ignoresPersistentStateOnLaunch": "NO",
        "debugDocumentVersioning": "YES",
        "debugServiceExtension": "internal",
        "allowLocationSimulation": "YES",
    ]
    if let launchStyle = launchStyle, launchStyle == .AppExtension {
      attributes["selectedDebuggerIdentifier"] = ""
      attributes["selectedLauncherIdentifier"] = "Xcode.IDEFoundation.Launcher.PosixSpawn"
      attributes["launchAutomaticallySubstyle"] = launchStyle.rawValue
    }
    if let customLLDBInitFile = self.customLLDBInitFile {
      attributes["customLLDBInitFile"] = customLLDBInitFile
    }

    element.setAttributesWith(attributes)
    if !self.commandlineArguments.isEmpty {
      element.addChild(commandlineArgumentsElement(self.commandlineArguments))
    }
    element.addChild(environmentVariablesElement(self.environmentVariables))
    if let preActionScript = preActionScripts[XcodeActionType.LaunchAction] {
        element.addChild(preActionElement(preActionScript))
    }
    if let postActionScript = postActionScripts[XcodeActionType.LaunchAction] {
        element.addChild(postActionElement(postActionScript))
    }

    if launchStyle == nil {
      if let reference = macroReference() {
        element.addChild(reference)
      }
    } else if launchStyle != .AppExtension {
      if let runnable = buildableProductRunnable(runnableDebuggingMode) {
        element.addChild(runnable)
      }
    } else if let extensionType = extensionType {
      if let runnable = extensionRunnable(extensionType: extensionType) {
        element.addChild(runnable)
      }
    } else if let target = target {
      
      
      localizedMessageLogger.warning("LegacyIOSExtensionNotSupported",
                                     comment: "Warning shown when generating an Xcode schema for target %1$@ which uses unsupported legacy ios_extension rule", values: target.name)
      if let reference = macroReference() {
        element.addChild(reference)
      }
    }
    return element
  }

  /// Settings for the Xcode "Profile" action.
  private func profileAction() -> XMLElement {
    let element = XMLElement(name: "ProfileAction")
    let attributes = [
        "buildConfiguration": profileActionBuildConfig,
        "shouldUseLaunchSchemeArgsEnv": "YES",
        "useCustomWorkingDirectory": "NO",
        "debugDocumentVersioning": "YES",
    ]
    element.setAttributesWith(attributes)
    let childRunnableDebuggingMode: RunnableDebuggingMode

    if let launchStyle = launchStyle {
      if launchStyle != .AppExtension {
        childRunnableDebuggingMode = runnableDebuggingMode
      } else {
        childRunnableDebuggingMode = .Default
      }
      if let runnable = buildableProductRunnable(childRunnableDebuggingMode) {
        element.addChild(runnable)
      }
    } else {
      
      if let runnable = macroReference() {
        element.addChild(runnable)
      }
    }

    return element
  }

  /// Settings for the Xcode "Analyze" action.
  private func analyzeAction() -> XMLElement {
    let element = XMLElement(name: "AnalyzeAction")
    element.setAttributesWith(["buildConfiguration": analyzeActionBuildConfig,
                                        ])
    return element
  }

  /// Settings for the Xcode "Archive" action.
  private func archiveAction() -> XMLElement {
    let element = XMLElement(name: "ArchiveAction")
    element.setAttributesWith(["buildConfiguration": archiveActionBuildConfig,
                                         "revealArchiveInOrganizer": "YES",
                                        ])
    return element
  }

  
  private func buildableProductRunnable(_ runnableDebuggingMode: RunnableDebuggingMode) -> XMLElement? {
    guard let target = target,
          let primaryTargetBuildableReference = primaryTargetBuildableReference else {
      return nil
    }
    let element: XMLElement
    var attributes = ["runnableDebuggingMode": runnableDebuggingMode.rawValue]
    switch runnableDebuggingMode {
      case .Remote:
        element = XMLElement(name: "RemoteRunnable")
        
        
        attributes["BundleIdentifier"] = "com.apple.carousel"
        if let productName = target.productName {
          
          attributes["RemotePath"] = "/\(productName)"
        }

      default:
        element = XMLElement(name: "BuildableProductRunnable")
    }
    element.setAttributesWith(attributes)
    element.addChild(primaryTargetBuildableReference.toXML())
    return element
  }

  private func extensionRunnable(extensionType: String) -> XMLElement? {
    guard let primaryTargetBuildableReference = primaryTargetBuildableReference else {
      return nil
    }
    let element: XMLElement
    let runnableDebuggingMode: RunnableDebuggingMode
    var attributes = [String: String]()

    switch extensionType {
      case "com.apple.intents-service":
        element = XMLElement(name: "RemoteRunnable")
        attributes["BundleIdentifier"] = "com.apple.springboard"
        attributes["RemotePath"] = "/Siri"
        runnableDebuggingMode = .Remote
      default:
        element = XMLElement(name: "BuildableProductRunnable")
        runnableDebuggingMode = .Default
    }
    attributes["runnableDebuggingMode"] = runnableDebuggingMode.rawValue

    element.setAttributesWith(attributes)
    element.addChild(primaryTargetBuildableReference.toXML())
    return element
  }

  
  
  private func macroReference() -> XMLElement? {
    guard let primaryTargetBuildableReference = primaryTargetBuildableReference else {
      return nil
    }
    let macroExpansion = XMLElement(name: "MacroExpansion")
    macroExpansion.addChild(primaryTargetBuildableReference.toXML())
    return macroExpansion
  }

  
  private func commandlineArgumentsElement(_ arguments: [String]) -> XMLElement {
    let element = XMLElement(name: "CommandLineArguments")
    for argument in arguments {
      let argumentElement = XMLElement(name: "CommandLineArgument")
      argumentElement.setAttributesAs([
        "argument": argument,
        "isEnabled": "YES"
      ])
      element.addChild(argumentElement)
    }
    return element
  }

  
  private func environmentVariablesElement(_ variables: [String: String]) -> XMLElement {
    let element = XMLElement(name:"EnvironmentVariables")
    for (key, value) in variables {
      let environmentVariable = XMLElement(name:"EnvironmentVariable")
      environmentVariable.setAttributesWith([
        "key": key,
        "value": value,
        "isEnabled": "YES"
      ])
      element.addChild(environmentVariable)
    }
    return element
  }

  
  private func preActionElement(_ script: String) -> XMLElement {
    let element = XMLElement(name:"PreActions")
    let executionAction = XMLElement(name:"ExecutionAction")
    let actionContent = XMLElement(name: "ActionContent")
    actionContent.setAttributesWith([
      "title": "Run Script",
      "scriptText": script
    ])

    if let primaryTargetBuildableReference = primaryTargetBuildableReference {
      let envBuildable = XMLElement(name: "EnvironmentBuildable")
      envBuildable.addChild(primaryTargetBuildableReference.toXML())
      actionContent.addChild(envBuildable)
    }
    executionAction.setAttributesWith(["ActionType": "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"])

    executionAction.addChild(actionContent)
    element.addChild(executionAction)
    return element
  }

  
  private func postActionElement(_ script: String) -> XMLElement {
    let element = XMLElement(name:"PostActions")
    let executionAction = XMLElement(name:"ExecutionAction")
    let actionContent = XMLElement(name: "ActionContent")
    actionContent.setAttributesWith([
      "title": "Run Script",
      "scriptText": script
    ])
    if let primaryTargetBuildableReference = primaryTargetBuildableReference {
      let envBuildable = XMLElement(name: "EnvironmentBuildable")
      envBuildable.addChild(primaryTargetBuildableReference.toXML())
      actionContent.addChild(envBuildable)
    }
    executionAction.setAttributesWith(["ActionType": "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction"])
    executionAction.addChild(actionContent)
    element.addChild(executionAction)
    return element
  }

  static func makeBuildActionEntryAttributes(_ analyze: Bool = true,
                                      test: Bool = true,
                                      run: Bool = true,
                                      profile: Bool = true,
                                      archive: Bool = true) -> BuildActionEntryAttributes {
    return [
      "buildForAnalyzing": analyze ? "YES" : "NO",
      "buildForTesting": test ? "YES" : "NO",
      "buildForRunning": run ? "YES" : "NO",
      "buildForProfiling": profile ? "YES" : "NO",
      "buildForArchiving": archive ? "YES" : "NO"
    ]
  }

  
  class BuildableReference {
    
    let buildableGID: String
    /// The product name of the target being built (e.g., "Application.app").
    let buildableName: String
    
    let targettName: String
    /// Name of the xcodeproj containing this reference (e.g., "Project.xcodeproj").
    let projectBundleName: String

    convenience init(target: PBXTarget, projectBundleName: String) {
      self.init(buildableGID: target.globalID,
                buildableName: target.buildableName,
                targettName: target.name,
                projectBundleName: projectBundleName)
    }

    init(buildableGID: String,
         buildableName: String,
         targettName: String,
         projectBundleName: String) {
      self.buildableGID = buildableGID
      self.buildableName = buildableName
      self.targettName = targettName
      self.projectBundleName = projectBundleName
    }

    func toXML() -> XMLElement {
      let element = XMLElement(name: "BuildableReference")
      let attributes = [
          "BuildableIdentifier": "primary",
          "BlueprintIdentifier": "\(buildableGID)",
          "BuildableName": "\(buildableName)",
          "BlueprintName": "\(targettName)",
          "ReferencedContainer": "container:\(projectBundleName)"
      ]
      element.setAttributesWith(attributes)
      return element
    }
  }
}
