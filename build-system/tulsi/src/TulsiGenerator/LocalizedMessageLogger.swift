

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



class LocalizedMessageLogger {

  
  struct LogSessionHandle {
    
    let name: String
    
    var startTime: Date
    
    let context: String?

    init(_ name: String, context: String?) {
      self.name = name
      self.startTime = Date()
      self.context = context
    }

    
    mutating func resetStartTime() {
      startTime = Date()
    }
  }

  let bundle: Bundle?

  init(bundle: Bundle?) {
    self.bundle = bundle
  }

  func startProfiling(_ name: String,
                      message: String? = nil,
                      context: String? = nil) -> LogSessionHandle {
    if let concreteMessage = message {
      syslogMessage(concreteMessage, context: context)
    }
    return LogSessionHandle(name, context: context)
  }

  func logProfilingEnd(_ token: LogSessionHandle) {
    let timeTaken = Date().timeIntervalSince(token.startTime)
    syslogMessage(String(format: "** Completed %@ in %.4fs",
                         token.name,
                         timeTaken),
                  context: token.context)
  }

  func error(_ key: String,
             comment: String,
             details: String? = nil,
             context: String? = nil,
             values: CVarArg...) {
    if bundle == nil { return }

    let formatString = NSLocalizedString(key, bundle: self.bundle!, comment: comment)
    let message = String(format: formatString, arguments: values)
    LogMessage.postError(message, details: details, context: context)
  }

  func warning(_ key: String,
               comment: String,
               details: String? = nil,
               context: String? = nil,
               values: CVarArg...) {
    if bundle == nil { return }

    let formatString = NSLocalizedString(key, bundle: self.bundle!, comment: comment)
    let message = String(format: formatString, arguments: values)
    LogMessage.postWarning(message, details: details, context: context)
  }

  func infoMessage(_ message: String, details: String? = nil, context: String? = nil) {
    LogMessage.postInfo(message, details: details, context: context)
  }

  func syslogMessage(_ message: String, details: String? = nil, context: String? = nil) {
    LogMessage.postSyslog(message, details: details, context: context)
  }

  func debugMessage(_ message: String, details: String? = nil, context: String? = nil) {
    LogMessage.postDebug(message, details: details, context: context)
  }

  static func bugWorthyComment(_ comment: String) -> String {
    return "\(comment). The resulting project will most likely be broken. A bug should be reported."
  }
}
