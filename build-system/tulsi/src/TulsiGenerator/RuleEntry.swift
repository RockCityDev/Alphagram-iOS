

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



public class RuleInfo: Equatable, Hashable, CustomDebugStringConvertible {
  public let label: BuildLabel
  public let type: String
  
  
  public let linkedTargetLabels: Set<BuildLabel>

  public var hashValue: Int {
    return label.hashValue ^ type.hashValue
  }

  public var debugDescription: String {
    return "\(Swift.type(of: self))(\(label) \(type))"
  }

  init(label: BuildLabel, type: String, linkedTargetLabels: Set<BuildLabel>) {
    self.label = label
    self.type = type
    self.linkedTargetLabels = linkedTargetLabels
  }

  func equals(_ other: RuleInfo) -> Bool {
    guard Swift.type(of: self) == Swift.type(of: other) else {
      return false
    }
    return self.type == other.type && self.label == other.label
  }
}



public class BazelFileInfo: Equatable, Hashable, CustomDebugStringConvertible {
  public enum TargetType: Int {
    case sourceFile
    case generatedFile
  }

  
  public let subPath: String

  
  public let rootPath: String

  
  public let targetType: TargetType

  
  public let isDirectory: Bool

  public lazy var fullPath: String = { [unowned self] in
    return NSString.path(withComponents: [self.rootPath, self.subPath])
  }()

  public lazy var uti: String? = { [unowned self] in
    return self.subPath.pbPathUTI
  }()

  public lazy var hashValue: Int = { [unowned self] in
    return self.subPath.hashValue &+
        self.rootPath.hashValue &+
        self.targetType.hashValue &+
        self.isDirectory.hashValue
  }()

  init?(info: AnyObject?) {
    guard let info = info as? [String: AnyObject] else {
      return nil
    }

    guard let subPath = info["path"] as? String,
              let isSourceFile = info["src"] as? Bool else {
      assertionFailure("Aspect provided a file info dictionary but was missing required keys")
      return nil
    }

    self.subPath = subPath
    if let rootPath = info["root"] as? String {
      
      self.rootPath = rootPath
    } else {
      self.rootPath = ""
    }
    self.targetType = isSourceFile ? .sourceFile : .generatedFile

    self.isDirectory = info["is_dir"] as? Bool ?? false
  }

  init(rootPath: String, subPath: String, isDirectory: Bool, targetType: TargetType) {
    self.rootPath = rootPath
    self.subPath = subPath
    self.isDirectory = isDirectory
    self.targetType = targetType
  }

  
  public lazy var debugDescription: String = { [unowned self] in
    return "{\(self.fullPath) \(self.isDirectory ? "<DIR> " : "")\(self.targetType)}"
  }()
}

public func ==(lhs: BazelFileInfo, rhs: BazelFileInfo) -> Bool {
  return lhs.targetType == rhs.targetType &&
      lhs.rootPath == rhs.rootPath &&
      lhs.subPath == rhs.subPath &&
      lhs.isDirectory == rhs.isDirectory
}




public final class RuleEntry: RuleInfo {
  
  
  public typealias IncludePath = (String, Bool)

  
  static let BuildTypeToTargetType = [
      "cc_binary": PBXTarget.ProductType.Application,
      "cc_library": PBXTarget.ProductType.StaticLibrary,
      "cc_test": PBXTarget.ProductType.Tool,
      
      
      "macos_command_line_application": PBXTarget.ProductType.Tool,
      "objc_library": PBXTarget.ProductType.StaticLibrary,
      "swift_library": PBXTarget.ProductType.StaticLibrary,
  ]

  
  
  
  public enum Attribute: String {
    case bridging_header
    
    
    case compiler_defines
    case copts
    case datamodels
    case enable_modules
    case has_swift_dependency
    case has_swift_info
    case launch_storyboard
    case pch
    case swift_language_version
    case swift_toolchain
    case swiftc_opts
    
    
    
    case supporting_files
    
    
    case test_host
  }

  /// Bazel attributes for this rule (e.g., "binary": <some label> on an ios_application).
  public let attributes: [Attribute: AnyObject]

  
  public let artifacts: [BazelFileInfo]

  
  public let objcDefines: [String]?

  
  public let swiftDefines: [String]?

  
  public let sourceFiles: [BazelFileInfo]

  
  public let nonARCSourceFiles: [BazelFileInfo]

  
  public let includePaths: [IncludePath]?

  
  public let dependencies: Set<BuildLabel>

  
  public let testDependencies: Set<BuildLabel>

  
  public let extensions: Set<BuildLabel>

  
  public let appClips: Set<BuildLabel>

  
  public let frameworkImports: [BazelFileInfo]

  
  public let secondaryArtifacts: [BazelFileInfo]

  
  public let swiftLanguageVersion: String?

  
  public let swiftToolchain: String?

  
  public let swiftTransitiveModules: [BazelFileInfo]

  
  public let objCModuleMaps: [BazelFileInfo]

  
  public let moduleName: String?

  
  public let deploymentTarget: DeploymentTarget?

  
  
  
  
  
  
  
  public var weakDependencies = Set<BuildLabel>()

  
  
  public var testSuiteDependencies: Set<BuildLabel> {
    guard type == "test_suite" else { return Set() }

    
    
    
    guard dependencies.isEmpty else { return dependencies }

    return weakDependencies
  }

  
  public let buildFilePath: String?

  
  public let bundleID: String?

  
  public let bundleName: String?

  
  let productType: PBXTarget.ProductType?

  
  public let extensionBundleID: String?

  
  public let extensionType: String?

  
  public let xcodeVersion: String?

  
  public var normalNonSourceArtifacts: [BazelFileInfo] {
    var artifacts = [BazelFileInfo]()
    if let description = attributes[.launch_storyboard] as? [String: AnyObject],
           let fileTarget = BazelFileInfo(info: description as AnyObject?) {
      artifacts.append(fileTarget)
    }

    if let fileTargets = parseFileDescriptionListAttribute(.supporting_files) {
      artifacts.append(contentsOf: fileTargets)
    }

    return artifacts
  }

  
  
  public var versionedNonSourceArtifacts: [BazelFileInfo] {
    if let fileTargets = parseFileDescriptionListAttribute(.datamodels) {
      return fileTargets
    }
    return []
  }

  
  public var projectArtifacts: [BazelFileInfo] {
    var artifacts = sourceFiles
    artifacts.append(contentsOf: nonARCSourceFiles)
    artifacts.append(contentsOf: frameworkImports)
    artifacts.append(contentsOf: normalNonSourceArtifacts)
    artifacts.append(contentsOf: versionedNonSourceArtifacts)
    return artifacts
  }

  private(set) lazy var pbxTargetType: PBXTarget.ProductType? = { [unowned self] in
    if let productType = self.productType {
      return productType
    }
    return RuleEntry.BuildTypeToTargetType[self.type]
  }()

  
  
  private(set) lazy var XcodeSDKRoot: String? = { [unowned self] in
    guard type != "cc_binary" && type != "cc_test" else {
      return PlatformType.macos.deviceSDK
    }
    if let platformType = self.deploymentTarget?.platform {
      return platformType.deviceSDK
    }
    return PlatformType.ios.deviceSDK
  }()

  init(label: BuildLabel,
       type: String,
       attributes: [String: AnyObject],
       artifacts: [BazelFileInfo] = [],
       sourceFiles: [BazelFileInfo] = [],
       nonARCSourceFiles: [BazelFileInfo] = [],
       dependencies: Set<BuildLabel> = Set(),
       testDependencies: Set<BuildLabel> = Set(),
       frameworkImports: [BazelFileInfo] = [],
       secondaryArtifacts: [BazelFileInfo] = [],
       weakDependencies: Set<BuildLabel>? = nil,
       extensions: Set<BuildLabel>? = nil,
       appClips: Set<BuildLabel>? = nil,
       bundleID: String? = nil,
       bundleName: String? = nil,
       productType: PBXTarget.ProductType? = nil,
       extensionBundleID: String? = nil,
       platformType: String? = nil,
       osDeploymentTarget: String? = nil,
       buildFilePath: String? = nil,
       objcDefines: [String]? = nil,
       swiftDefines: [String]? = nil,
       includePaths: [IncludePath]? = nil,
       swiftLanguageVersion: String? = nil,
       swiftToolchain: String? = nil,
       swiftTransitiveModules: [BazelFileInfo] = [],
       objCModuleMaps: [BazelFileInfo] = [],
       moduleName: String? = nil,
       extensionType: String? = nil,
       xcodeVersion: String? = nil) {

    var checkedAttributes = [Attribute: AnyObject]()
    for (key, value) in attributes {
      guard let checkedKey = Attribute(rawValue: key) else {
        print("Tulsi rule \(label.value) - Ignoring unknown attribute key \(key)")
        assertionFailure("Unknown attribute key \(key)")
        continue
      }
      checkedAttributes[checkedKey] = value
    }
    self.attributes = checkedAttributes
    let parsedPlatformType: PlatformType?
    if let platformTypeStr = platformType {
      parsedPlatformType = PlatformType(rawValue: platformTypeStr)
    } else {
      parsedPlatformType = nil
    }

    self.artifacts = artifacts
    self.sourceFiles = sourceFiles
    self.nonARCSourceFiles = nonARCSourceFiles
    self.dependencies = dependencies
    self.testDependencies = testDependencies
    self.frameworkImports = frameworkImports
    self.secondaryArtifacts = secondaryArtifacts
    if let weakDependencies = weakDependencies {
      self.weakDependencies = weakDependencies
    }
    self.extensions = extensions ?? Set()
    self.appClips = appClips ?? Set()
    self.bundleID = bundleID
    self.bundleName = bundleName
    self.productType = productType
    self.extensionBundleID = extensionBundleID
    var deploymentTarget: DeploymentTarget? = nil
    if let platform = parsedPlatformType,
        let osVersion = osDeploymentTarget {
      deploymentTarget = DeploymentTarget(platform: platform, osVersion: osVersion)
    }
    self.deploymentTarget = deploymentTarget
    self.buildFilePath = buildFilePath
    self.objcDefines = objcDefines
    self.moduleName = moduleName
    self.swiftDefines = swiftDefines
    self.includePaths = includePaths
    self.swiftLanguageVersion = swiftLanguageVersion
    self.swiftToolchain = swiftToolchain
    self.swiftTransitiveModules = swiftTransitiveModules
    self.xcodeVersion = xcodeVersion

    
    
    
    
    
    
    
    let targetsToAvoid = testDependencies + [label]
    let moduleMapsToAvoid = targetsToAvoid.compactMap { (targetLabel: BuildLabel) -> String? in
      return targetLabel.asFileName
    }
    if !moduleMapsToAvoid.isEmpty {
      self.objCModuleMaps = objCModuleMaps.filter { moduleMapFileInfo in
        let moduleMapPath = moduleMapFileInfo.fullPath
        for mapToAvoid in moduleMapsToAvoid {
          if moduleMapPath.hasSuffix("\(mapToAvoid).modulemaps/module.modulemap")
            || moduleMapPath.hasSuffix("\(mapToAvoid).swift.modulemap")
          {
            return false
          }
        }
        return true
      }
    } else {
      self.objCModuleMaps = objCModuleMaps
    }
    self.extensionType = extensionType

    var linkedTargetLabels = Set<BuildLabel>()
    if let hostLabelString = self.attributes[.test_host] as? String {
      linkedTargetLabels.insert(BuildLabel(hostLabelString))
    }

    super.init(label: label, type: type, linkedTargetLabels: linkedTargetLabels)
  }

  convenience init(label: String,
                   type: String,
                   attributes: [String: AnyObject],
                   artifacts: [BazelFileInfo] = [],
                   sourceFiles: [BazelFileInfo] = [],
                   nonARCSourceFiles: [BazelFileInfo] = [],
                   dependencies: Set<BuildLabel> = Set(),
                   testDependencies: Set<BuildLabel> = Set(),
                   frameworkImports: [BazelFileInfo] = [],
                   secondaryArtifacts: [BazelFileInfo] = [],
                   weakDependencies: Set<BuildLabel>? = nil,
                   extensions: Set<BuildLabel>? = nil,
                   appClips: Set<BuildLabel>? = nil,
                   bundleID: String? = nil,
                   bundleName: String? = nil,
                   productType: PBXTarget.ProductType? = nil,
                   extensionBundleID: String? = nil,
                   platformType: String? = nil,
                   osDeploymentTarget: String? = nil,
                   buildFilePath: String? = nil,
                   objcDefines: [String]? = nil,
                   swiftDefines: [String]? = nil,
                   includePaths: [IncludePath]? = nil,
                   swiftLanguageVersion: String? = nil,
                   swiftToolchain: String? = nil,
                   swiftTransitiveModules: [BazelFileInfo] = [],
                   objCModuleMaps: [BazelFileInfo] = [],
                   moduleName: String? = nil,
                   extensionType: String? = nil,
                   xcodeVersion: String? = nil) {
    self.init(label: BuildLabel(label),
              type: type,
              attributes: attributes,
              artifacts: artifacts,
              sourceFiles: sourceFiles,
              nonARCSourceFiles: nonARCSourceFiles,
              dependencies: dependencies,
              testDependencies: testDependencies,
              frameworkImports: frameworkImports,
              secondaryArtifacts: secondaryArtifacts,
              weakDependencies: weakDependencies,
              extensions: extensions,
              appClips: appClips,
              bundleID: bundleID,
              bundleName: bundleName,
              productType: productType,
              extensionBundleID: extensionBundleID,
              platformType: platformType,
              osDeploymentTarget: osDeploymentTarget,
              buildFilePath: buildFilePath,
              objcDefines: objcDefines,
              swiftDefines: swiftDefines,
              includePaths: includePaths,
              swiftLanguageVersion: swiftLanguageVersion,
              swiftToolchain: swiftToolchain,
              swiftTransitiveModules: swiftTransitiveModules,
              objCModuleMaps: objCModuleMaps,
              moduleName: moduleName,
              extensionType: extensionType,
              xcodeVersion: xcodeVersion)
  }

  

  private func parseFileDescriptionListAttribute(_ attribute: RuleEntry.Attribute) -> [BazelFileInfo]? {
    guard let descriptions = attributes[attribute] as? [[String: AnyObject]] else {
      return nil
    }

    var fileTargets = [BazelFileInfo]()
    for description in descriptions {
      guard let target = BazelFileInfo(info: description as AnyObject?) else {
        assertionFailure("Failed to resolve file description to a file target")
        continue
      }
      fileTargets.append(target)
    }
    return fileTargets
  }

  override func equals(_ other: RuleInfo) -> Bool {
    guard super.equals(other), let entry = other as? RuleEntry else {
      return false
    }
    return deploymentTarget == entry.deploymentTarget
  }
}



public func ==(lhs: RuleInfo, rhs: RuleInfo) -> Bool {
  return lhs.equals(rhs)
}
