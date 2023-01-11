

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator


class MockLocalizedMessageLogger: LocalizedMessageLogger {
  var syslogMessages = [String]()
  var infoMessages = [String]()
  var warningMessageKeys = [String]()

  let nonFatalWarningKeys = Set([
    "BootstrapLLDBInitFailed",
    "CleanCachedDsymsFailed",
  ])

  var errorMessageKeys = [String]()

  init() {
    super.init(bundle: nil)
  }

  override func error(
    _ key: String, comment: String, details: String?, context: String?, values: CVarArg...
  ) {
    errorMessageKeys.append(key)
  }

  override func warning(
    _ key: String, comment: String, details: String?, context: String?, values: CVarArg...
  ) {
    warningMessageKeys.append(key)
  }

  override func infoMessage(_ message: String, details: String?, context: String?) {
    infoMessages.append(message)
  }

  override func syslogMessage(_ message: String, details: String?, context: String?) {
    syslogMessages.append(message)
  }

  func assertNoErrors(_ file: StaticString = #file, line: UInt = #line) {
    XCTAssert(
      errorMessageKeys.isEmpty,
      "Unexpected error messages printed: \(errorMessageKeys)",
      file: file,
      line: line)
  }

  func assertNoWarnings(_ file: StaticString = #file, line: UInt = #line) {
    let hasOnlyNonFatalWarnings = Set(warningMessageKeys).isSubset(of: nonFatalWarningKeys)
    XCTAssert(
      warningMessageKeys.isEmpty || hasOnlyNonFatalWarnings,
      "Unexpected warning messages printed: \(warningMessageKeys)",
      file: file,
      line: line)
  }
}
