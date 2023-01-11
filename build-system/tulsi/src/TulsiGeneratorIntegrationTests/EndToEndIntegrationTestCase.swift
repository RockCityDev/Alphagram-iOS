

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest
@testable import BazelIntegrationTestCase
@testable import TulsiGenerator




class EndToEndIntegrationTestCase : BazelIntegrationTestCase {
  enum Error: Swift.Error {
    
    case testSubdirectoryNotCreated
    
    case projectGenerationFailure(String)
    
    case userBuildScriptInvocationFailure(String)
  }

  let extraDebugFlags = ["--define=TULSI_TEST=dbg"]
  let extraReleaseFlags = ["--define=TULSI_TEST=rel"]
  let fakeBazelURL = URL(fileURLWithPath: "/fake/tulsi_test_bazel", isDirectory: false)
  let testTulsiVersion = "9.99.999.9999"

  final func validateDiff(_ diffLines: [String], for resourceName: String, file: StaticString = #file, line: UInt = #line) {
    guard !diffLines.isEmpty else { return }
    let message = "\(resourceName) xcodeproj does not match its golden. Diff output:\n\(diffLines.joined(separator: "\n"))"
    XCTFail(message, file: file, line: line)
  }

  final func diffProjectAt(_ projectURL: URL,
                           againstGoldenProject resourceName: String,
                           file: StaticString = #file,
                           line: UInt = #line) -> [String] {
    guard let hashing = ProcessInfo.processInfo.environment["SWIFT_DETERMINISTIC_HASHING"],
        hashing == "1" else {
      XCTFail("Must define environment variable \"SWIFT_DETERMINISTIC_HASHING=1\", or golden tests will fail.")
      return []
    }
    let goldenProjectURL = workspaceRootURL.appendingPathComponent(fakeBazelWorkspace
                                                                       .resourcesPathBase,
                                                                   isDirectory: true)
        .appendingPathComponent("GoldenProjects/\(resourceName).xcodeproj", isDirectory: true)
    guard FileManager.default.fileExists(atPath: goldenProjectURL.path) else {
      assertionFailure("Missing required test resource file \(resourceName).xcodeproj")
      XCTFail("Missing required test resource file \(resourceName).xcodeproj",
              file: file,
              line: line)
      return []
    }

    var diffOutput = [String]()
    let semaphore = DispatchSemaphore(value: 0)
    let process = ProcessRunner.createProcess("/usr/bin/diff",
                                              arguments: ["-r",
                                                          
                                                          
                                                          
                                                          
                                                          "--exclude=.tulsi",
                                                          projectURL.path,
                                                          goldenProjectURL.path]) {
      completionInfo in
        defer {
          semaphore.signal()
        }
        if let stdout = NSString(data: completionInfo.stdout, encoding: String.Encoding.utf8.rawValue) {
          diffOutput = stdout.components(separatedBy: "\n").filter({ !$0.isEmpty })
        } else {
          XCTFail("No output received for diff command", file: file, line: line)
        }
    }
    process.currentDirectoryPath = workspaceRootURL.path
    process.launch()

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    return diffOutput
  }

  final func copyOutput(source: URL, outputDir: String) throws {
    if testUndeclaredOutputsDir != nil {
      guard let testOutputURL = makeTestSubdirectory(outputDir,
                                                     rootDirectory: testUndeclaredOutputsDir,
                                                     cleanupOnTeardown: false) else {
        throw Error.testSubdirectoryNotCreated
      }
      let testOutputProjURL = testOutputURL.appendingPathComponent(source.lastPathComponent)
      if FileManager.default.fileExists(atPath: testOutputProjURL.path) {
        try FileManager.default.removeItem(at: testOutputProjURL)
      }
      try FileManager.default.copyItem(at: source, to: testOutputProjURL)
    }
  }

  final func validateBuildCommandForProject(_ projectURL: URL,
                                            swift: Bool = false,
                                            options: TulsiOptionSet = TulsiOptionSet(),
                                            targets: [String]) throws {
    let actualDebug = try userBuildCommandForProject(projectURL, release: false, targets: targets)
    let actualRelease = try userBuildCommandForProject(projectURL, release: true, targets: targets)
    let (debug, release) = expectedBuildCommands(swift: swift, options: options, targets: targets)

    XCTAssertEqual(actualDebug, debug)
    XCTAssertEqual(actualRelease, release)
  }

  final func expectedBuildCommands(swift: Bool,
                                   options: TulsiOptionSet,
                                   targets: [String]) -> (String, String) {
    let provider = BazelSettingsProvider(universalFlags: bazelUniversalFlags)
    let features = BazelBuildSettingsFeatures.enabledFeatures(options: options)
    let dbg = provider.tulsiFlags(hasSwift: swift, options: options, features: features).debug
    let rel = provider.tulsiFlags(hasSwift: swift, options: options, features: features).release

    let config: PlatformConfiguration
    if let identifier = options[.ProjectGenerationPlatformConfiguration].commonValue,
      let parsedConfig = PlatformConfiguration(identifier: identifier) {
      config = parsedConfig
    } else {
      config = PlatformConfiguration.defaultConfiguration
    }

    func buildCommand(extraBuildFlags: [String], tulsiFlags: BazelFlags) -> String {
      var args = [fakeBazelURL.path]
      args.append(contentsOf: bazelStartupOptions)
      args.append(contentsOf: tulsiFlags.startup)
      args.append("build")
      args.append(contentsOf: extraBuildFlags)
      args.append(contentsOf: bazelBuildOptions)
      args.append(contentsOf: config.bazelFlags)
      args.append(contentsOf: tulsiFlags.build)
      args.append("--tool_tag=tulsi:user_build")
      args.append(contentsOf: targets)

      return args.map { $0.escapingForShell }.joined(separator: " ")
    }

    let debugCommand = buildCommand(extraBuildFlags: extraDebugFlags, tulsiFlags: dbg)
    let releaseCommand = buildCommand(extraBuildFlags: extraReleaseFlags, tulsiFlags: rel)

    return (debugCommand, releaseCommand)
  }

  final func userBuildCommandForProject(_ projectURL: URL,
                                        release: Bool = false,
                                        targets: [String],
                                        file: StaticString = #file,
                                        line: UInt = #line) throws -> String {
    let expectedScriptURL = projectURL.appendingPathComponent(".tulsi/Scripts/user_build.py",
                                                               isDirectory: false)
    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: expectedScriptURL.path) else {
      throw Error.userBuildScriptInvocationFailure(
          "user_build.py script not found: expected at path \(expectedScriptURL.path)")
    }

    var output = "<none>"
    let semaphore = DispatchSemaphore(value: 0)
    var args = [
        "--norun",
    ]
    if release {
      args.append("--release")
    }
    args.append(contentsOf: targets)

    let process = ProcessRunner.createProcess(
      expectedScriptURL.path,
      arguments: args,
      messageLogger: localizedMessageLogger
    ) { completionInfo in
        defer {
          semaphore.signal()
        }
        let exitcode = completionInfo.terminationStatus
        guard exitcode == 0 else {
          let stderr =
            String(data: completionInfo.stderr, encoding: .utf8) ?? "<no stderr>"
          XCTFail("user_build.py returned \(exitcode). stderr: \(stderr)", file: file, line: line)
          return
        }
        if let stdout = String(data: completionInfo.stdout, encoding: .utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            !stdout.isEmpty {
          output = stdout
        } else {
          let stderr =
              String(data: completionInfo.stderr, encoding: .utf8) ?? "<no stderr>"
          XCTFail("user_build.py had no stdout. stderr: \(stderr)", file: file, line: line)
        }
    }
    process.currentDirectoryPath = workspaceRootURL.path
    process.launch()

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    return output
  }

  final func generateProjectNamed(_ projectName: String,
                                  buildTargets: [RuleInfo],
                                  pathFilters: [String],
                                  additionalFilePaths: [String] = [],
                                  outputDir: String,
                                  options: TulsiOptionSet = TulsiOptionSet()) throws -> URL {
    if !bazelStartupOptions.isEmpty {
      let startupFlags = bazelStartupOptions.joined(separator: " ")
      options[.BazelBuildStartupOptionsDebug].projectValue = startupFlags
      options[.BazelBuildStartupOptionsRelease].projectValue = startupFlags
    }

    let debugBuildOptions = extraDebugFlags + bazelBuildOptions
    let releaseBuildOptions = extraReleaseFlags + bazelBuildOptions

    options[.BazelBuildOptionsDebug].projectValue = debugBuildOptions.joined(separator: " ")
    options[.BazelBuildOptionsRelease].projectValue = releaseBuildOptions.joined(separator: " ")

    let bazelURLParam = TulsiParameter(value: fakeBazelURL, source: .explicitlyProvided)
    let config = TulsiGeneratorConfig(projectName: projectName,
                                      buildTargets: buildTargets,
                                      pathFilters: Set<String>(pathFilters),
                                      additionalFilePaths: additionalFilePaths,
                                      options: options,
                                      bazelURL: bazelURLParam)

    guard let outputFolderURL = makeXcodeProjPath(outputDir) else {
      throw Error.testSubdirectoryNotCreated
    }

    let projectGenerator = TulsiXcodeProjectGenerator(workspaceRootURL: workspaceRootURL,
                                                      config: config,
                                                      extractorBazelURL: bazelURL,
                                                      tulsiVersion: testTulsiVersion)
    
    
    projectGenerator.xcodeProjectGenerator.suppressCompilerDefines = true
    
    projectGenerator.xcodeProjectGenerator.suppressUpdatingShellCommands = true
    
    projectGenerator.xcodeProjectGenerator.suppressModuleCachePrunerInstallation = true
    
    projectGenerator.xcodeProjectGenerator.usernameFetcher = { "_TEST_USER_" }
    
    projectGenerator.xcodeProjectGenerator.redactSymlinksToBazelOutput = true
    let errorInfo: String
    do {
      let generatedProjURL = try projectGenerator.generateXcodeProjectInFolder(outputFolderURL)
      try copyOutput(source: generatedProjURL, outputDir: outputDir)
      return generatedProjURL
    } catch TulsiXcodeProjectGenerator.GeneratorError.unsupportedTargetType(let targetType) {
      errorInfo = "Unsupported target type: \(targetType)"
    } catch TulsiXcodeProjectGenerator.GeneratorError.serializationFailed(let details) {
      errorInfo = "General failure: \(details)"
    } catch let error {
      errorInfo = "Unexpected failure: \(error)"
    }
    throw Error.projectGenerationFailure(errorInfo)
  }
}
