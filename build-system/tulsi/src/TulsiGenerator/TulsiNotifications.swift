

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



///   "level": String - The level of the message (see TulsiMessageLevel)
///   "message": String - The body of the message.
///   "details": String? - Optional detailed information about the message.
///   "context": String? - Optional contextual information about the message.
public let TulsiMessageNotification = "com.google.tulsi.Message"


public enum TulsiMessageLevel: String {
  case Error, Warning, Syslog, Info, Debug
}


@objc
public enum LogMessagePriority: Int {
  case error, warning, syslog, info, debug
}

extension TulsiMessageLevel {
  public var logRank: LogMessagePriority {
    switch self {
    case .Error:
      return .error
    case .Warning:
      return .warning
    case .Syslog:
      return .syslog
    case .Info:
      return .info
    case .Debug:
      return .debug
    }
  }
}

public struct LogMessage {
  public let level: TulsiMessageLevel
  public let message: String
  public let details: String?
  public let context: String?

  
  public static func displayPendingErrors() {
    let userInfo = [ "displayErrors" : true ]
    NotificationCenter.default.post(name: Notification.Name(rawValue: TulsiMessageNotification),
                                    object: nil,
                                    userInfo: userInfo)
  }

  
  
  
  public static func postError(_ message: String, details: String? = nil, context: String? = nil) {
    postMessage(.Error, message: message, details: details, context: context)
  }

  public static func postWarning(_ message: String, details: String? = nil, context: String? = nil) {
    postMessage(.Warning, message: message, details: details, context: context)
  }

  public static func postInfo(_ message: String, details: String? = nil, context: String? = nil) {
    postMessage(.Info, message: message, details: details, context: context)
  }

  public static func postSyslog(_ message: String, details: String? = nil, context: String? = nil) {
    postMessage(.Syslog, message: message, details: details, context: context)
  }

  public static func postDebug(_ message: String, details: String? = nil, context: String? = nil) {
    postMessage(.Debug, message: message, details: details, context: context)
  }

  
  private static func postMessage(_ level: TulsiMessageLevel,
                                  message: String,
                                  details: String? = nil,
                                  context: String? = nil) {
    var userInfo = [
        "level": level.rawValue,
        "message": message,
    ]
    if let details = details {
      userInfo["details"] = details
    }
    if let context = context {
      userInfo["context"] = context
    }

    NotificationCenter.default.post(name: Notification.Name(rawValue: TulsiMessageNotification),
                                                            object: nil,
                                                            userInfo: userInfo)
  }

  public init?(notification: Notification) {
    guard notification.name.rawValue == TulsiMessageNotification,
          let userInfo = notification.userInfo,
          let levelString = userInfo["level"] as? String,
          let message = userInfo["message"] as? String,
          let level = TulsiMessageLevel(rawValue: levelString) else {
      return nil
    }

    self.level = level
    self.message = message
    self.details = userInfo["details"] as? String
    self.context = userInfo["context"] as? String
  }
}



///   "name": String - The name of the task.
///   "maxValue": Int - The maximum value of the task
///   "progressNotificationName" - The name of the notification that will be sent when progress

///   "startIndeterminate" - Whether or not there might be an indeterminate delay before the first

public let ProgressUpdatingTaskDidStart = "com.google.tulsi.progressUpdatingTaskDidStart"
public let ProgressUpdatingTaskName = "name"
public let ProgressUpdatingTaskMaxValue = "maxValue"
public let ProgressUpdatingTaskStartIndeterminate = "startIndeterminate"


/// The userInfo dictionary contains "value": Int - the new progress
public let ProgressUpdatingTaskProgress = "com.google.tulsi.progressUpdatingTaskProgress"
public let ProgressUpdatingTaskProgressValue = "value"


public let GatheringIndexerSources = "gatheringIndexerSources"


public let GeneratingBuildTargets = "generatingBuildTargets"


public let GeneratingIndexerTargets = "generatingIndexerTargets"


public let InstallingScripts = "installingScripts"


public let InstallingUtilities = "installingUtilities"


public let InstallingGeneratorConfig = "installingGeneratorConfig"


public let SerializingXcodeProject = "serializingXcodeProject"


public let SourceFileExtraction = "sourceFileExtraction"


public let WorkspaceInfoExtraction = "workspaceInfoExtraction"
