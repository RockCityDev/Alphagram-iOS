

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class ShellEscapingTests: XCTestCase {

  func testSurroundedBySingleQuotes() {
    XCTAssertEqual("foobar".escapingForShell, "foobar")
    XCTAssertEqual("this is a string".escapingForShell, "'this is a string'")
    XCTAssertEqual("$PWD".escapingForShell, "'$PWD'")
  }

  func testEscapesSingleQuotes() {
    XCTAssertEqual("foo'bar".escapingForShell, "'foo'\\''bar'")
    XCTAssertEqual("this''string".escapingForShell, "'this'\\'''\\''string'")
  }
}
