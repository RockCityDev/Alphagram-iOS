

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation




class CommandLineSplitter {
  let scriptPath: String

  init() {
    scriptPath = Bundle(for: type(of: self)).path(forResource: "command_line_splitter",
                                                                      ofType: "sh")!
  }

  
  
  func splitCommandLine(_ commandLine: String) -> [String]? {
    if commandLine.isEmpty { return [] }

    var splitCommands: [String]? = nil
    let semaphore = DispatchSemaphore(value: 0)
    let process = ProcessRunner.createProcess(scriptPath, arguments: [commandLine]) {
      completionInfo in
        defer { semaphore.signal() }

        guard completionInfo.terminationStatus == 0,
            let stdout = NSString(data: completionInfo.stdout, encoding: String.Encoding.utf8.rawValue) else {
          return
        }
        let split = stdout.components(separatedBy: CharacterSet.newlines)
        splitCommands = [String](split.dropLast())
    }
    process.launch()
    _ = semaphore.wait(timeout: DispatchTime.distantFuture)

    return splitCommands
  }
}
