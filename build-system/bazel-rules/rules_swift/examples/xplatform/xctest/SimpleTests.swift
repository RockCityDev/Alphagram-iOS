

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

class SimpleTests: XCTestCase {
  var value: Int = 0

  override func setUp() {
    value = 4
  }

  func testThatWillSucceed() {
    XCTAssertEqual(value, 4)
  }

  func testThatWillFailIfChanged() {
    
    
    
    XCTAssertEqual(value, 4)
  }

  static var allTests = [
    ("testThatWillSucceed", testThatWillSucceed),
    ("testThatWillFailIfChanged", testThatWillFailIfChanged),
  ]
}
