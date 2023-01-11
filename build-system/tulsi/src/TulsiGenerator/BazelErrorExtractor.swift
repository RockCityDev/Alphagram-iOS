

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



struct BazelErrorExtractor {
  static let DefaultErrors = 3

  static func firstErrorLinesFromData(_ data: Data, maxErrors: Int = DefaultErrors) -> String? {
    guard let stderr = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
    return firstErrorLinesFromString(stderr as String, maxErrors: maxErrors)
  }

  static func firstErrorLinesFromString(_ output: String, maxErrors: Int = DefaultErrors) -> String? {
    func isNewLogMessage(_ line: String) -> Bool {
      for newLogMessagePrefix in ["ERROR:", "INFO:", "WARNING:"] {
        if line.hasPrefix(newLogMessagePrefix) {
          return true
        }
      }
      return false
    }

    var errorMessages = [String]()
    var tracebackErrorMessages = Set<String>()
    var activeTraceback = [String]()

    for line in output.components(separatedBy: "\n") {
      if !activeTraceback.isEmpty {
        if isNewLogMessage(line) {
          if !errorMessages.isEmpty {
            let lastMessageIndex = errorMessages.count - 1
            errorMessages[lastMessageIndex].append(activeTraceback.joined(separator: "\n"))
            tracebackErrorMessages.insert(errorMessages[lastMessageIndex])
          }
          activeTraceback = []
        } else {
          activeTraceback.append(line)
        }
      } else if (line.hasPrefix("Traceback")) {
        activeTraceback.append(line)
      }

      if (line.hasPrefix("ERROR:")) {
        errorMessages.append(line)
      }
    }

    if !activeTraceback.isEmpty && !errorMessages.isEmpty {
      let lastMessageIndex = errorMessages.count - 1
      errorMessages[lastMessageIndex].append(activeTraceback.joined(separator: "\n"))
      tracebackErrorMessages.insert(errorMessages[lastMessageIndex])
    }

    
    
    
    
    var errorSnippet = errorMessages.prefix(maxErrors).joined(separator: "\n")
    tracebackErrorMessages.subtract(errorMessages.prefix(maxErrors))
    errorSnippet.append(tracebackErrorMessages.joined(separator: "\n"))

    if maxErrors < errorMessages.count {
      errorSnippet += "\n..."
    }
    return errorSnippet
  }

  static func firstErrorLinesOrLastLinesFromString(_ output: String,
                                                   maxErrors: Int = DefaultErrors) -> String? {
    if let errorLines = firstErrorLinesFromString(output, maxErrors: maxErrors) {
      return errorLines
    }
    let errorLines = output.components(separatedBy: "\n").filter({ !$0.isEmpty })
    let numErrorLinesToShow = min(errorLines.count, maxErrors)
    var errorSnippet = errorLines.suffix(numErrorLinesToShow).joined(separator: "\n")
    if numErrorLinesToShow < errorLines.count {
      errorSnippet = "...\n" + errorSnippet
    }
    return errorSnippet
  }

  private init() {
  }
}
