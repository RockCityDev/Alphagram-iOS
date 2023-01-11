

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import ButtonsMac

class ButtonsMacTests: XCTestCase {

  func testIncrementLabel() {
    let viewController = ViewController()
    let label = NSTextField()
    label.stringValue = "0"
    viewController.incrementLabel(label: label)
    XCTAssertEqual(label.stringValue, "1")
  }

}
