

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

class ButtonsMacUITests: XCTestCase {

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    XCUIApplication().launch()
  }

  func testLabelIncrementsWithClick() {
    let app = XCUIApplication()
    let clickButton = app.buttons["clickButton"]
    let clickCountLabel = app.staticTexts["clickCount"]

    for tapCount in 1...3 {
      clickButton.click()
      XCTAssertEqual(clickCountLabel.value! as! String, String(tapCount))
    }
  }

}

