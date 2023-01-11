

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation




public final class TulsiProject {
  public enum ProjectError: Error {
    
    case serializationFailed(String)
    
    case badInputFilePath
    
    case deserializationFailed(String)
    
    case failedToReadAdditionalOptionsData(String)
  }

  
  public static let ProjectFilename = "project.tulsiconf"

  
  
  public static let SharedConfigsPath = "sharedConfigs"

  
  
  public static let UserConfigsPath = "userConfigs"

  static let ProjectNameKey = "projectName"
  static let WorkspaceRootKey = "workspaceRoot"
  static let PackagesKey = "packages"
  static let ConfigDefaultsKey = "configDefaults"

  

  
  public let projectName: String

  
  public var projectBundleURL: URL

  
  public let workspaceRootURL: URL

  
  public var bazelPackages: [String]

  public let options: TulsiOptionSet
  public let hasExplicitOptions: Bool

  

  
  public var bazelURL: URL? {
    didSet {
      options[.BazelPath].projectValue = bazelURL?.path
    }
  }

  
  public static var perUserFilename: String {
    return "\(NSUserName()).tulsiconf-user"
  }

  public static func load(_ projectBundleURL: URL) throws -> TulsiProject {
    let fileManager = FileManager.default
    let projectFileURL = projectBundleURL.appendingPathComponent(TulsiProject.ProjectFilename)
    guard let data = fileManager.contents(atPath: projectFileURL.path) else {
      throw ProjectError.badInputFilePath
    }
    return try TulsiProject(data: data, projectBundleURL: projectBundleURL)
  }

  public init(projectName: String,
              projectBundleURL: URL,
              workspaceRootURL: URL,
              bazelPackages: [String] = [],
              options: TulsiOptionSet? = nil) {
    self.projectName = projectName
    self.projectBundleURL = projectBundleURL
    self.workspaceRootURL = workspaceRootURL
    self.bazelPackages = bazelPackages

    if let options = options {
      self.options = options
      hasExplicitOptions = true
    } else {
      self.options = TulsiOptionSet()
      hasExplicitOptions = false
    }
    if let bazelPath = self.options[.BazelPath].projectValue {
      self.bazelURL = URL(fileURLWithPath: bazelPath)
    } else {
      self.bazelURL = BazelLocator.bazelURL
      self.options[.BazelPath].projectValue = self.bazelURL?.path
    }
    self.options[.WorkspaceRootPath].projectValue = workspaceRootURL.path
  }

  public convenience init(data: Data,
                          projectBundleURL: URL,
                          additionalOptionData: Data? = nil) throws {
    do {
      guard let dict = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String: AnyObject] else {
        throw ProjectError.deserializationFailed("File is not of dictionary type")
      }

      let projectName = dict[TulsiProject.ProjectNameKey] as? String ?? "Unnamed Tulsi Project"
      guard let relativeWorkspacePath = dict[TulsiProject.WorkspaceRootKey] as? String else {
        throw ProjectError.deserializationFailed("Missing required value for \(TulsiProject.WorkspaceRootKey)")
      }
      if (relativeWorkspacePath as NSString).isAbsolutePath {
        throw ProjectError.deserializationFailed("\(TulsiProject.WorkspaceRootKey) may not be an absolute path")
      }

      var workspaceRootURL = projectBundleURL.appendingPathComponent(relativeWorkspacePath,
                                                                     isDirectory: true)
      
      workspaceRootURL = workspaceRootURL.standardizedFileURL

      let bazelPackages = dict[TulsiProject.PackagesKey] as? [String] ?? []

      let options: TulsiOptionSet?
      if let configDefaults = dict[TulsiProject.ConfigDefaultsKey] as? [String: AnyObject] {
        var optionsDict = TulsiOptionSet.getOptionsFromContainerDictionary(configDefaults) ?? [:]
        if let additionalOptionData = additionalOptionData {
          try TulsiProject.updateOptionsDict(&optionsDict,
                                             withAdditionalOptionData: additionalOptionData)
        }
        options = TulsiOptionSet(fromDictionary: optionsDict)
      } else {
        options = nil
      }

      self.init(projectName: projectName,
                projectBundleURL: projectBundleURL,
                workspaceRootURL: workspaceRootURL,
                bazelPackages: bazelPackages,
                options: options)
    } catch let e as ProjectError {
      throw e
    } catch let e as NSError {
      throw ProjectError.deserializationFailed(e.localizedDescription)
    } catch {
      assertionFailure("Unexpected exception")
      throw ProjectError.serializationFailed("Unexpected exception")
    }
  }

  public func workspaceRelativePathForURL(_ absoluteURL: URL) -> String? {
    return workspaceRootURL.relativePathTo(absoluteURL)
  }

  public func save() throws -> NSData {
    var configDefaults = [String: Any]()
    
    options.saveShareableOptionsIntoDictionary(&configDefaults)

    let dict: [String: Any] = [
        TulsiProject.ProjectNameKey: projectName,
        TulsiProject.WorkspaceRootKey: projectBundleURL.relativePathTo(workspaceRootURL)!,
        TulsiProject.PackagesKey: bazelPackages.sorted(),
        TulsiProject.ConfigDefaultsKey: configDefaults,
    ]

    do {
      return try JSONSerialization.tulsi_newlineTerminatedUnescapedData(jsonObject: dict,
                                                                        options: [.prettyPrinted, .sortedKeys])
    } catch let e as NSError {
      throw ProjectError.serializationFailed(e.localizedDescription)
    } catch {
      assertionFailure("Unexpected exception")
      throw ProjectError.serializationFailed("Unexpected exception")
    }
  }

  public func savePerUserSettings() throws -> NSData? {
    var dict = [String: Any]()
    options.savePerUserOptionsIntoDictionary(&dict)
    if dict.isEmpty { return nil }
    do {
      return try JSONSerialization.tulsi_newlineTerminatedUnescapedData(jsonObject: dict,
                                                                        options: [.prettyPrinted, .sortedKeys])
    } catch let e as NSError {
      throw ProjectError.serializationFailed(e.localizedDescription)
    } catch {
      throw ProjectError.serializationFailed("Unexpected exception")
    }
  }

  

  private static func updateOptionsDict(_ optionsDict: inout TulsiOptionSet.PersistenceType,
                                        withAdditionalOptionData data: Data) throws {
    do {
      guard let jsonDict = try JSONSerialization.jsonObject(with: data,
                                                                      options: JSONSerialization.ReadingOptions()) as? [String: AnyObject] else {
        throw ProjectError.failedToReadAdditionalOptionsData("File contents are invalid")
      }
      guard let newOptions = TulsiOptionSet.getOptionsFromContainerDictionary(jsonDict) else {
        return
      }
      for (key, value) in newOptions {
        optionsDict[key] = value
      }
    } catch let e as ProjectError {
      throw e
    } catch let e as NSError {
      throw ProjectError.failedToReadAdditionalOptionsData(e.localizedDescription)
    } catch {
      assertionFailure("Unexpected exception")
      throw ProjectError.failedToReadAdditionalOptionsData("Unexpected exception")
    }
  }
}
