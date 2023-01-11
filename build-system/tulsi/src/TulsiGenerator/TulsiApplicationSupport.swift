

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

class ApplicationSupport {

  private let fileManager: FileManager
  let tulsiFolder: URL

  init?(fileManager: FileManager = .default) {
    
    if ProcessInfo.processInfo.environment["TEST_SRCDIR"] != nil {
      return nil
    }
    
    
    guard let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String else { return nil }
    guard let folder = fileManager.urls(for: .applicationSupportDirectory,
                                        in: .userDomainMask).first else {
      return nil
    }

    self.fileManager = fileManager
    self.tulsiFolder = folder.appendingPathComponent(appName, isDirectory: true)
  }

  
  
  func copyTulsiAspectFiles(tulsiVersion: String) throws -> String {
    let bundle = Bundle(for: type(of: self))
    let aspectWorkspaceFile = bundle.url(forResource: "WORKSPACE", withExtension: nil)!
    let aspectBuildFile = bundle.url(forResource: "BUILD", withExtension: nil)!
    let tulsiFiles = bundle.urls(forResourcesWithExtension: nil, subdirectory: "tulsi")!

    let bazelSubpath = (tulsiVersion as NSString).appendingPathComponent("Bazel")
    let bazelPath = try installFiles([aspectWorkspaceFile, aspectBuildFile], toSubpath: bazelSubpath)

    let tulsiAspectsSubpath = (bazelSubpath as NSString).appendingPathComponent("tulsi")
    try installFiles(tulsiFiles, toSubpath: tulsiAspectsSubpath)

    return bazelPath.path
  }

  @discardableResult
  private func installFiles(_ files: [URL],
                            toSubpath subpath: String) throws -> URL {
    let folder = tulsiFolder.appendingPathComponent(subpath, isDirectory: true)

    try createDirectory(atURL: folder)

    for sourceURL in files {
      let filename = sourceURL.lastPathComponent

      guard let targetURL = URL(string: filename, relativeTo: folder) else {
        throw TulsiXcodeProjectGenerator.GeneratorError.serializationFailed(
            "Unable to resolve URL for \(filename) in \(folder.path).")
      }
      do {
        try copyFileIfNeeded(fromURL: sourceURL, toURL: targetURL)
      }
    }
    return folder
  }

  private func copyFileIfNeeded(fromURL: URL, toURL: URL) throws {
    do {
      
      if fileManager.fileExists(atPath: toURL.path) {
        guard !fileManager.contentsEqual(atPath: fromURL.path, andPath: toURL.path) else {
          return;
        }
        print("Overwriting \(toURL.path) as its contents changed.")
        try fileManager.removeItem(at: toURL)
      }
      try fileManager.copyItem(at: fromURL, to: toURL)
    }
  }

  private func createDirectory(atURL url: URL) throws {
    var isDirectory: ObjCBool = false
    let fileExists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)

    guard !fileExists || !isDirectory.boolValue else { return }

    try fileManager.createDirectory(at: url,
                                    withIntermediateDirectories: true,
                                    attributes: nil)
  }
}
