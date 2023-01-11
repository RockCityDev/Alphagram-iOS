

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import examples_apple_objc_interop_PrintStream

@objc(OIPrinter)
public class Printer: NSObject {

  private let stream: OIPrintStream
  private let prefix: String

  @objc public init(prefix: NSString) {
    self.stream = OIPrintStream(fileHandle: .standardOutput)
    self.prefix = prefix as String
  }

  @objc public func print(_ message: NSString) {
    stream.print("\(prefix)\(message)")
  }
}
