





struct CompatibilityIssue: CustomStringConvertible {
  let message: String
  let context: String

  var description: String {
    "[\(context)] \(message)"
  }
}




final class CompatibilityTracker {

  

  init(mode: Mode) {
    self.mode = mode
  }

  

  
  enum Mode {
    
    
    case abort

    
    case track
  }

  enum Error: Swift.Error {
    case encounteredCompatibilityIssue(CompatibilityIssue)
  }

  
  func logIssue(message: String, context: String) throws {
    LottieLogger.shared.assert(!context.isEmpty, "Compatibility issue context is unexpectedly empty")

    let issue = CompatibilityIssue(
      
      
      message: message.replacingOccurrences(of: "\n", with: " "),
      context: context)

    switch mode {
    case .abort:
      throw CompatibilityTracker.Error.encounteredCompatibilityIssue(issue)
    case .track:
      issues.append(issue)
    }
  }

  
  
  func assert(
    _ condition: Bool,
    _ message: @autoclosure () -> String,
    context: @autoclosure () -> String)
    throws
  {
    if !condition {
      try logIssue(message: message(), context: context())
    }
  }

  
  
  func reportCompatibilityIssues(_ handler: ([CompatibilityIssue]) -> Void) {
    handler(issues)
    issues = []
  }

  

  private let mode: Mode

  
  private var issues = [CompatibilityIssue]()

}



protocol CompatibilityTrackerProviding {
  var compatibilityTracker: CompatibilityTracker { get }
  var compatibilityIssueContext: String { get }
}

extension CompatibilityTrackerProviding {
  
  func logCompatibilityIssue(_ message: String) throws {
    try compatibilityTracker.logIssue(message: message, context: compatibilityIssueContext)
  }

  
  
  func compatibilityAssert(
    _ condition: Bool,
    _ message: @autoclosure () -> String)
    throws
  {
    try compatibilityTracker.assert(condition, message(), context: compatibilityIssueContext)
  }
}



extension LayerContext: CompatibilityTrackerProviding {
  var compatibilityIssueContext: String {
    layerName
  }
}



extension LayerAnimationContext: CompatibilityTrackerProviding {
  var compatibilityIssueContext: String {
    currentKeypath.fullPath
  }
}
