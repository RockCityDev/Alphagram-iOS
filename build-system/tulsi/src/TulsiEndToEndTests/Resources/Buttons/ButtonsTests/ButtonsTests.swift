

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest
@testable import Buttons

class ButtonsTests: XCTestCase {

  func testIncrementLabel() {
    let viewController = ViewController()
    let label = UILabel()
    label.text = "0"
    viewController.incrementLabel(label: label)
    XCTAssertEqual(label.text!, "1")
  }

}
