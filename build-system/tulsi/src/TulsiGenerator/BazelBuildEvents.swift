

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



class BazelBuildEvent {
  let files: [String]

  init(eventDictionary: [String: AnyObject]) {
    var files = [String]()
    if let namedSetOfFiles = eventDictionary["namedSetOfFiles"] as? [String: AnyObject],
       let fileDicts = namedSetOfFiles["files"] as? [[String: AnyObject]] {
      for fileDict in fileDicts {
        guard let uri = fileDict["uri"] as? String else { continue }
        
        if uri.hasPrefix("file://") {
          let index = uri.index(uri.startIndex, offsetBy: 7)
          files.append(String(uri[index...]))
        }
      }
    }
    self.files = files
  }
}

class BazelBuildEventsReader {

  private let filePath: String
  private let localizedMessageLogger: LocalizedMessageLogger

  init(filePath: String, localizedMessageLogger: LocalizedMessageLogger) {
    self.filePath = filePath
    self.localizedMessageLogger = localizedMessageLogger
  }

  func readAllEvents() throws -> [BazelBuildEvent] {
    let string = try String(contentsOfFile: filePath, encoding: .utf8)
    var newEvents = [BazelBuildEvent]()
    string.enumerateLines { line, _ in
      guard let event = self.parseBuildEventFromLine(line) else { return }
      newEvents.append(event)
    }
    return newEvents
  }

  func parseBuildEventFromLine(_ line: String) -> BazelBuildEvent? {
    guard let data = line.data(using: .utf8) else {
      localizedMessageLogger.warning("BazelParseBuildEventFailed",
                                     comment: "Error to show when unable to parse a Bazel Build Event JSON dictionary. Additional information: %1$@.",
                                     values:"Failed to convert string to UTF-8")
      return nil
    }
    do {
      guard let json = try JSONSerialization.jsonObject(with: data,
                                                        options: JSONSerialization.ReadingOptions())
                                                        as? [String: AnyObject] else {
        localizedMessageLogger.warning("BazelParseBuildEventFailed",
                                       comment: "Error to show when unable to parse a Bazel Build Event JSON dictionary. Additional information: %1$@.",
                                       values:"Failed to parse event JSON from string: " + line)
        return nil
      }
      return BazelBuildEvent(eventDictionary: json)
    } catch let e as NSError {
      localizedMessageLogger.warning("BazelParseBuildEventFailed",
                                     comment: "Error to show when unable to parse a Bazel Build Event JSON dictionary. Additional information: %1$@.",
                                     values:"Error when parsing JSON: " + e.localizedDescription)
      return nil
    } catch {
      localizedMessageLogger.warning("BazelParseBuildEventFailed",
                                     comment: "Error to show when unable to parse a Bazel Build Event JSON dictionary. Additional information: %1$@.",
                                     values:"Unknown error when parsing JSON from string: " + line)
      return nil
    }
  }
}
