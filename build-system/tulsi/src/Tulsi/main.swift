

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator

private func main() {
  
  let commandlineParser = TulsiCommandlineParser()

  let consoleLogger = EventLogger(verboseLevel: commandlineParser.arguments.verboseLevel,
                                  logToFile: commandlineParser.arguments.logToFile)
  consoleLogger.startLogging()

  if !commandlineParser.commandlineSentinalFound {
    _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    exit(0)
  }

  let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
  LogMessage.postSyslog("Tulsi CLI: version \(version)")

  let queue = DispatchQueue(label: "com.google.Tulsi.xcodeProjectGenerator", attributes: [])
  queue.async {
    do {
      switch commandlineParser.mode {
        case .invalid:
          print("Missing mode parameter. Please see the help message.")
          exit(2)

        case .tulsiProjectCreator:
          let generator = HeadlessTulsiProjectCreator(arguments: commandlineParser.arguments)
          try generator.generate()

        case .xcodeProjectGenerator:
          let generator = HeadlessXcodeProjectGenerator(arguments: commandlineParser.arguments)
          try generator.generate()
      }
    } catch HeadlessModeError.invalidConfigPath(let reason) {
      print("Invalid \(TulsiCommandlineParser.ParamGeneratorConfigLong) param: \(reason)")
      exit(11)
    } catch HeadlessModeError.invalidConfigFileContents(let reason) {
      print("Failed to read the given generator config: \(reason)")
      exit(12)
    } catch HeadlessModeError.explicitOutputOptionRequired {
      print("The \(TulsiCommandlineParser.ParamOutputFolderLong) option is required for the selected config")
      exit(13)
    } catch HeadlessModeError.invalidBazelPath {
      print("The path to the bazel binary is invalid")
      exit(14)
    } catch HeadlessModeError.generationFailed {
      print("Xcode project generation failed")
      exit(15)
    } catch HeadlessModeError.invalidWorkspaceRootOverride {
      print("The parameter given as the workspace root path is not a valid directory")
      exit(16)
    } catch HeadlessModeError.invalidProjectFileContents(let reason) {
      print("Failed to read the given project: \(reason)")
      exit(20)
    } catch HeadlessModeError.missingBazelPath {
      print("The path to the bazel binary must be specified")
      exit(21)
    } catch HeadlessModeError.missingWORKSPACEFile(let path) {
      print("The workspace root at '\(path)' does not contain a Bazel WORKSPACE file.")
      exit(21)
    } catch HeadlessModeError.missingBuildTargets {
      print("At least one build target must be specified with the \(TulsiCommandlineParser.ParamBuildTargetLong) parameter.")
      exit(22)
    } catch HeadlessModeError.invalidProjectBundleName {
      print("The parameter given to \(TulsiCommandlineParser.ParamCreateTulsiProj) is invalid. " +
                "It must be the name of the .tulsiproj bundle to be created, without any other " +
                "path elements.")
      exit(23)
    } catch HeadlessModeError.bazelTargetProcessingFailed {
      print("Failed to identify any valid build targets.")
      exit(24)
    } catch let e as NSError {
      print("An unexpected exception occurred: \(e.localizedDescription)")
      exit(126)
    } catch {
      print("An unexpected exception occurred")
      exit(127)
    }

    
    
    
    exit(0)
  }

  dispatchMain()
}



main()
