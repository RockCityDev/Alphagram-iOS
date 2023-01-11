

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


class BazelWorkspacePathInfoFetcher {
  
  private var executionRoot: String? = nil
  
  private var outputBase: String? = nil
  
  private var bazelBinSymlinkName: String? = nil

  
  private let bazelURL: URL
  
  private let workspaceRootURL: URL
  
  private let bazelUniversalFlags: BazelFlags

  private let localizedMessageLogger: LocalizedMessageLogger
  private let semaphore: DispatchSemaphore
  private var fetchCompleted = false

  init(bazelURL: URL, workspaceRootURL: URL, bazelUniversalFlags: BazelFlags,
       localizedMessageLogger: LocalizedMessageLogger) {
    self.bazelURL = bazelURL
    self.workspaceRootURL = workspaceRootURL
    self.bazelUniversalFlags = bazelUniversalFlags
    self.localizedMessageLogger = localizedMessageLogger

    semaphore = DispatchSemaphore(value: 0)
    fetchWorkspaceInfo()
  }

  
  func getExecutionRoot() -> String {
    if !fetchCompleted { waitForCompletion() }

    guard let executionRoot = executionRoot else {
      localizedMessageLogger.error("ExecutionRootNotFound",
                                   comment: "Execution root should have been extracted from the workspace.")
      return ""
    }
    return executionRoot
  }

  
  func getOutputBase() -> String {
    if !fetchCompleted { waitForCompletion() }

    guard let outputBase = outputBase else {
      localizedMessageLogger.error("OutputBaseNotFound",
                                   comment: "Output base should have been extracted from the workspace.")
      return ""
    }
    return outputBase
  }

  
  func getBazelBinPath() -> String {
    if !fetchCompleted { waitForCompletion() }

    guard let bazelBinSymlinkName = bazelBinSymlinkName else {
      localizedMessageLogger.error("BazelBinSymlinkNameNotFound",
                                   comment: "Bazel bin symlink should have been extracted from the workspace.")
      return ""
    }

    return bazelBinSymlinkName
  }

  

  
  private func waitForCompletion() {
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    semaphore.signal()
  }

  
  private func fetchWorkspaceInfo() {
    let profilingStart = localizedMessageLogger.startProfiling("get_package_path",
                                                               message: "Fetching bazel path info")
    guard FileManager.default.fileExists(atPath: bazelURL.path) else {
      localizedMessageLogger.error("BazelBinaryNotFound",
                                   comment: "Error to show when the bazel binary cannot be found at the previously saved location %1$@.",
                                   values: bazelURL as NSURL)
      fetchCompleted = true
      return
    }
    var arguments = [String]()
    arguments.append(contentsOf: bazelUniversalFlags.startup)
    arguments.append("info")
    arguments.append(contentsOf: bazelUniversalFlags.build)

    let process = TulsiProcessRunner.createProcess(bazelURL.path,
                                                   arguments: arguments,
                                                   messageLogger: localizedMessageLogger,
                                                   loggingIdentifier: "bazel_get_package_path" ) {
      completionInfo in
        defer {
          self.localizedMessageLogger.logProfilingEnd(profilingStart)
          self.fetchCompleted = true
          self.semaphore.signal()
        }
        if completionInfo.process.terminationStatus == 0 {
          if let stdout = NSString(data: completionInfo.stdout, encoding: String.Encoding.utf8.rawValue) {
            self.extractWorkspaceInfo(stdout)
            return
          }
        }

        let stderr = NSString(data: completionInfo.stderr, encoding: String.Encoding.utf8.rawValue)
        let debugInfoFormatString = NSLocalizedString("DebugInfoForBazelCommand",
                                                      bundle: Bundle(for: type(of: self)),
                                                      comment: "Provides general information about a Bazel failure; a more detailed error may be reported elsewhere. The Bazel command is %1$@, exit code is %2$d, stderr %3$@.")
        let debugInfo = String(format: debugInfoFormatString,
                               completionInfo.commandlineString,
                               completionInfo.terminationStatus,
                               stderr ?? "<No STDERR>")
        self.localizedMessageLogger.infoMessage(debugInfo)
        self.localizedMessageLogger.error("BazelWorkspaceInfoQueryFailed",
                                          comment: "Extracting path info from bazel failed. The exit code is %1$d.",
                                          details: stderr as String?,
                                          values: completionInfo.process.terminationStatus)
    }
    process.currentDirectoryPath = workspaceRootURL.path
    process.launch()
  }

  private func extractWorkspaceInfo(_ output: NSString) {
    let lines = output.components(separatedBy: CharacterSet.newlines)
    for line in lines {
      let components = line.components(separatedBy: ": ")
      guard let key = components.first, !key.isEmpty else { continue }
      let valueComponents = components.dropFirst()
      let value = valueComponents.joined(separator: ": ")

      if key.hasSuffix("-bin") {
        if (bazelBinSymlinkName != nil) {
          self.localizedMessageLogger.warning("MultipleBazelWorkspaceSymlinkNames",
                                    comment: "Error to show when more than one workspace key has a suffix of '-bin'.",
                                    details: "More than one key in the workspace ends in '-bin'. Only the first key will be used.")
          continue
        }
        bazelBinSymlinkName = key
      }

      if key == "execution_root" {
        executionRoot = value
      } else if key == "output_base" {
        outputBase = value
      }
    }
  }
}
