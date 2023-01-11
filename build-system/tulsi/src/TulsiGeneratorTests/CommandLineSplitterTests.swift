

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class CommandLineSplitterTests: XCTestCase {
  var splitter: CommandLineSplitter! = nil

  override func setUp() {
    super.setUp()
    splitter = CommandLineSplitter()
  }

  func testSimpleArgs() {
    checkSplit("", [])

    checkSplit("'broken \"", nil)
    checkSplit("\"broken ", nil)

    checkSplit("\"\"", [""])
    checkSplit("Single", ["Single"])
    checkSplit("one two", ["one", "two"])
  }

  func testQuotedArgs() {
    checkSplit("one 'two single quoted'", ["one", "two single quoted"])
    checkSplit("one \"two double quoted\"", ["one", "two double quoted"])
    checkSplit("one \"two double quoted\"", ["one", "two double quoted"])

    checkSplit("one=one \"two double quoted\"", ["one=one", "two double quoted"])
    checkSplit("\"a=b=c\" \"two double quoted\"", ["a=b=c", "two double quoted"])
    checkSplit("\"a=\\\"b = c\\\"\" \"two double quoted\"", ["a=\"b = c\"", "two double quoted"])

    checkSplit("\"quoted text       \"", ["quoted text       "])
    checkSplit("'quoted text       '", ["quoted text       "])
  }

  

  private func checkSplit(_ commandLine: String, _ expected: [String]?, line: UInt = #line) {
    let split = splitter.splitCommandLine(commandLine)
    if expected == nil {
      XCTAssertNil(split, line: line)
      return
    }
    XCTAssertNotNil(split, line: line)
    if let split = split {
      XCTAssertEqual(split, expected!, line: line)
    }
  }
}
