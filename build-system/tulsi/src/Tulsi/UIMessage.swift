

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator


protocol MessageLogProtocol: AnyObject {
  var messages: [UIMessage] { get }
}



final class UIMessage: NSObject, NSPasteboardWriting {
  @objc dynamic let text: String
  @objc dynamic let messagePriority: TulsiGenerator.LogMessagePriority
  let timestamp = Date()

  init(text: String, type: TulsiGenerator.LogMessagePriority) {
    self.text = text
    self.messagePriority = type
  }

  

  func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
    return [NSPasteboard.PasteboardType.string]
  }

  func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
    if type == NSPasteboard.PasteboardType.string {
      let timeString = DateFormatter.localizedString(from: timestamp,
                                                               dateStyle: .none,
                                                               timeStyle: .medium)
      return "[\(timeString)](\(messagePriority.rawValue)): \(text)"
    }
    return nil
  }
}
