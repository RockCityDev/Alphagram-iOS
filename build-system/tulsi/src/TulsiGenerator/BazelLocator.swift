

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



public struct BazelLocator {

  
  
  public static let DefaultBazelURLKey = "defaultBazelURL"

  public static var bazelURL: URL? {
    if let bazelURL = UserDefaults.standard.url(forKey: BazelLocator.DefaultBazelURLKey),
      FileManager.default.fileExists(atPath: bazelURL.path) {
      return bazelURL
    }

    

    let semaphore = DispatchSemaphore(value: 0)
    var completionInfo: ProcessRunner.CompletionInfo?
    let task = TulsiProcessRunner.createProcess("/bin/bash",
                                                arguments: ["-l", "-c", "which bazel"]) {
                                                  processCompletionInfo in
                                                  defer { semaphore.signal() }
                                                  completionInfo = processCompletionInfo
    }
    task.launch()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)

    guard let info = completionInfo else {
      return nil
    }
    guard info.terminationStatus == 0 else {
      return nil
    }

    guard let stdout = String(data: info.stdout, encoding: String.Encoding.utf8) else {
      return nil
    }
    let bazelURL = URL(fileURLWithPath: stdout.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                       isDirectory: false)
    guard FileManager.default.fileExists(atPath: bazelURL.path) else {
      return nil
    }

    UserDefaults.standard.set(bazelURL, forKey: BazelLocator.DefaultBazelURLKey)
    return bazelURL
  }

  

  private init() {
  }
}
