

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



public final class TulsiProcessRunner {

  public typealias CompletionHandler = (ProcessRunner.CompletionInfo) -> Void

  private static var defaultEnvironment: [String: String] = {
    var environment = ProcessInfo.processInfo.environment
    if let cfBundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      environment["TULSI_VERSION"] = cfBundleVersion
    }
    return environment
  }()

  
  
  static func createProcess(_ launchPath: String,
                            arguments: [String],
                            environment: [String: String] = [:],
                            messageLogger: LocalizedMessageLogger? = nil,
                            loggingIdentifier: String? = nil,
                            terminationHandler: @escaping CompletionHandler) -> Process {
    let env = environment.merging(defaultEnvironment) { (current, _) in
      return current
    }
    return ProcessRunner.createProcess(launchPath,
                                       arguments: arguments,
                                       environment: env,
                                       messageLogger: messageLogger,
                                       loggingIdentifier: loggingIdentifier,
                                       terminationHandler: terminationHandler)
  }
}
