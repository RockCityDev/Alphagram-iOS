

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import BazelIntegrationTestCase
@testable import TulsiGenerator



class TulsiEndToEndTest: BazelIntegrationTestCase {
  fileprivate static let simulatorName = "tulsie2e-\(UUID().uuidString.prefix(8))"
  fileprivate static let targetVersion = "14.5"

  let fileManager = FileManager.default
  var runfilesWorkspaceURL: URL! = nil

  
  
  static func setUpFailure(_ msg: String) {
    print("SETUP FAILURE: \(msg)")
  }

  
  override class func setUp() {
    super.setUp()

    let targetDevice = "iPhone 12 Pro"
    let deviceName = targetDevice.replacingOccurrences(of: " ", with: "-")
    let deviceVersion = TulsiEndToEndTest.targetVersion.replacingOccurrences(of: ".", with: "-")
    let typeId = "com.apple.CoreSimulator.SimDeviceType.\(deviceName)"
    let runtimeId = "com.apple.CoreSimulator.SimRuntime.iOS-\(deviceVersion)"
    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcrun",
      arguments: [
        "simctl",
        "create",
        TulsiEndToEndTest.simulatorName,
        typeId,
        runtimeId
      ])

    if completionInfo.terminationStatus != 0 {
      if let stderr = String(data: completionInfo.stderr, encoding: .utf8), !stderr.isEmpty {
        TulsiEndToEndTest.setUpFailure(
          "\(completionInfo.commandlineString) failed with error: \(stderr)")
      } else {
        TulsiEndToEndTest.setUpFailure(
          "\(completionInfo.commandlineString) encountered an error. Exit code \(completionInfo.terminationStatus)."
        )
      }
    }

    
    if let stdout = String(data: completionInfo.stdout, encoding: .utf8), stdout.isEmpty {
      TulsiEndToEndTest.setUpFailure("No UUID was ouputted for newly created simulator.")
    }
  }

  
  override class func tearDown() {
    super.tearDown()

    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcrun",
      arguments: [
        "simctl",
        "delete",
        TulsiEndToEndTest.simulatorName
      ])

    if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
      print(
        """
            \(completionInfo.commandlineString) failed with exit code: \(completionInfo.terminationStatus)
            Error: \(error)
            """
      )
    }
  }

  
  override func setUp() {
    super.setUp()
    super.continueAfterFailure = false
    runfilesWorkspaceURL = fakeBazelWorkspace.runfilesWorkspaceURL
    XCTAssertNotNil(runfilesWorkspaceURL, "runfilesWorkspaceURL must be not be nil after setup.")

    
    
    
    if !fileManager.fileExists(atPath: workspaceRootURL.appendingPathComponent("Tulsi.app").path) {
      
      let tulsiZipPath = "tulsi.zip"
      let tulsiZipURL = runfilesWorkspaceURL.appendingPathComponent(
        tulsiZipPath, isDirectory: false)
      let completionInfo = ProcessRunner.launchProcessSync(
        "/usr/bin/unzip",
        arguments: [
          tulsiZipURL.path,
          "-d",
          workspaceRootURL.path
        ])

      if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
        TulsiEndToEndTest.setUpFailure(error)
      }
    }

    
    self.runSimctlCommand("boot", onSimulator: TulsiEndToEndTest.simulatorName)
  }

  
  override func tearDown() {
    super.tearDown()
    self.runSimctlCommand("shutdown", onSimulator: TulsiEndToEndTest.simulatorName)
    self.runSimctlCommand("erase", onSimulator: TulsiEndToEndTest.simulatorName)
  }

  
  func copyDataToFakeWorkspace(_ path: String) -> Bool {
    let sourceURL = runfilesWorkspaceURL.appendingPathComponent(path, isDirectory: false)
    let destURL = workspaceRootURL.appendingPathComponent(path, isDirectory: false)
    do {
      if !fileManager.fileExists(atPath: sourceURL.path) {
        XCTFail("Source file  \(sourceURL.path) does not exist.")
      }
      if fileManager.fileExists(atPath: destURL.path) {
        try fileManager.removeItem(at: destURL)
      }

      
      try fileManager.deepCopyItem(at: sourceURL, to: destURL)
      return true
    } catch let e as NSError {
      print(e.localizedDescription)
      return false
    }
  }

  
  func generateXcodeProject(tulsiProject path: String, config: String) -> URL {
    let tulsiBinURL = workspaceRootURL.appendingPathComponent(
      "Tulsi.app/Contents/MacOS/Tulsi", isDirectory: false)
    XCTAssert(fileManager.fileExists(atPath: tulsiBinURL.path), "Tulsi binary is missing.")

    let projectURL = workspaceRootURL.appendingPathComponent(path, isDirectory: true)
    XCTAssert(fileManager.fileExists(atPath: projectURL.path), "Tulsi project is missing.")
    let configPath = projectURL.path + ":" + config
    var args: [String] = [
      "--",
      "--genconfig",
      configPath,
      "--outputfolder",
      workspaceRootURL.path,
      "--bazel",
      bazelURL.path,
      "--no-open-xcode"
    ]
    if !bazelBuildOptions.isEmpty {
      args.append("--build-options")
      args.append(bazelBuildOptions.joined(separator: " "))
    }

    
    let completionInfo = ProcessRunner.launchProcessSync(
      tulsiBinURL.path,
      arguments: args)

    if let stdoutput = String(data: completionInfo.stdout, encoding: .utf8) {
      print(stdoutput)
    }
    if let erroutput = String(data: completionInfo.stderr, encoding: .utf8) {
      print(erroutput)
    }

    let filename = TulsiGeneratorConfig.sanitizeFilename("\(config).xcodeproj")
    let xcodeProjectURL = workspaceRootURL.appendingPathComponent(filename, isDirectory: true)

    
    addTeardownBlock {
      do {
        if self.fileManager.fileExists(atPath: xcodeProjectURL.path) {
          try self.fileManager.removeItem(at: xcodeProjectURL)
          XCTAssertFalse(self.fileManager.fileExists(atPath: xcodeProjectURL.path))
        }
      } catch {
        XCTFail("Error while deleting generated Xcode project: \(error)")
      }
    }

    return xcodeProjectURL
  }

  /// Returns the "json" style dictionary of a project.
  
  
  
  
  
  fileprivate func xcodeProjectDictionary(_ xcodeProjectURL: URL) -> [String: Any]? {
    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcodebuild",
      arguments: [
        "-list",
        "-json",
        "-project",
        xcodeProjectURL.path
      ])
    guard let stdoutput = String(data: completionInfo.stdout, encoding: .utf8),
      !stdoutput.isEmpty
    else {
      if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
        XCTFail(error)
      } else {
        XCTFail("Xcode project tests did not return success.")
      }
      return nil
    }
    guard
      let jsonDeserialized = try? JSONSerialization.jsonObject(
        with: completionInfo.stdout, options: [])
    else {
      XCTFail("Unable to decode from json: \(stdoutput)")
      return nil
    }
    guard let jsonResponse = jsonDeserialized as? [String: Any] else {
      XCTFail("Unable to decode from json as [String: Any]: \(stdoutput)")
      return nil
    }
    guard let project = jsonResponse["project"] as? [String: Any] else {
      XCTFail("Unable to extract project from \(jsonResponse)")
      return nil
    }
    return project
  }

  
  
  
  
  
  
  func targetsOfXcodeProject(_ xcodeProjectURL: URL) -> [String] {
    guard let project = xcodeProjectDictionary(xcodeProjectURL) else {
      XCTFail("Unable to extract project for \(xcodeProjectURL)")
      return []
    }
    guard let targets = project["targets"] as? [String] else {
      XCTFail("Unable to extract targets from \(project)")
      return []
    }
    return targets
  }

  
  
  
  
  
  func buildXcodeTarget(_ xcodeProjectURL: URL, target: String, configuration: String = "Release") -> String {
    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcodebuild",
      arguments: [
        "build",
        "-project",
        xcodeProjectURL.path,
        "-target",
        target,
        // "destination" seems to be ignored when specifying a target, it might only apply
        
        
        
        "-arch",
        "x86_64",
        "-sdk",
        "iphonesimulator",
        "-configuration",
        configuration,
        "SYMROOT=xcodeBuild"
      ])

    if let stdoutput = String(data: completionInfo.stdout, encoding: .utf8),
      !stdoutput.isEmpty,
      let result = stdoutput.split(separator: "\n").last
    {
      if (String(result) != "** BUILD SUCCEEDED **") {
        print(stdoutput)
        XCTFail(
          "\(completionInfo.commandlineString) did not return build success. Exit code: \(completionInfo.terminationStatus)"
        )
      }

      return String(stdoutput)
    } else if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
      XCTFail(error)
    } else {
      XCTFail("Xcode project build did not return success \(xcodeProjectURL):\(target).")
    }

    return ""
  }

  
  
  func testXcodeProject(_ xcodeProjectURL: URL, scheme: String) {
    let destination
      = "platform=iOS Simulator,name=\(TulsiEndToEndTest.simulatorName),OS=\(TulsiEndToEndTest.targetVersion)"
    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcodebuild",
      arguments: [
        "test",
        "-project",
        xcodeProjectURL.path,
        "-scheme",
        scheme,
        
        "-destination",
        destination
      ])

    if let stdoutput = String(data: completionInfo.stdout, encoding: .utf8),
      !stdoutput.isEmpty,
      let result = stdoutput.split(separator: "\n").last
    {
      XCTAssert(stdoutput.contains("Rsyncing"), "Failed to find 'Rsyncing' in:\n\(stdoutput)")
      if (String(result) != "** TEST SUCCEEDED **") {
        print(stdoutput)
        XCTFail(
          "\(completionInfo.commandlineString) did not return test success. Exit code: \(completionInfo.terminationStatus)"
        )
      }
    } else if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
      XCTFail(error)
    } else {
      XCTFail("Xcode project tests did not return success \(xcodeProjectURL):\(scheme).")
    }
  }

  
  
  fileprivate func runSimctlCommand(_ command: String, onSimulator target: String) {
    let completionInfo = ProcessRunner.launchProcessSync(
      "/usr/bin/xcrun",
      arguments: [
        "simctl",
        command,
        target
      ])

    if let error = String(data: completionInfo.stderr, encoding: .utf8), !error.isEmpty {
      print(
        """
            \(completionInfo.commandlineString) failed with exit code: \(completionInfo.terminationStatus)
            Error: \(error)
            """
      )
    }
  }
}

extension FileManager {
  
  func deepCopyItem(at sourceURL: URL, to destURL: URL) throws {
    do {
      try self.createDirectory(
        atPath: destURL.deletingLastPathComponent().path, withIntermediateDirectories: true)
      let rootPath = sourceURL.path
      if let rootAttributes = try? self.attributesOfItem(atPath: rootPath) {
        if rootAttributes[FileAttributeKey.type] as? FileAttributeType == FileAttributeType
          .typeSymbolicLink
        {
          let resolvedRootPath = try self.destinationOfSymbolicLink(atPath: rootPath)
          try self.copyItem(atPath: resolvedRootPath, toPath: destURL.path)
        } else {
          try self.copyItem(at: sourceURL, to: destURL)
        }
      }

      let path = destURL.path
      if let paths = self.subpaths(atPath: path) {
        for subpath in paths {
          let fullSubpath = path + "/" + subpath
          if let attributes = try? self.attributesOfItem(atPath: fullSubpath) {
            
            
            if attributes[FileAttributeKey.type] as? FileAttributeType == FileAttributeType
              .typeSymbolicLink
            {
              let resolvedPath = try self.destinationOfSymbolicLink(atPath: fullSubpath)
              try self.removeItem(atPath: fullSubpath)
              try self.copyItem(atPath: resolvedPath, toPath: fullSubpath)
            }
          }
        }
      }
    }
  }
}
