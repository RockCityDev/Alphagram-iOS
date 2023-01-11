

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {

  @IBOutlet weak var label: WKInterfaceLabel!

  var contents = 0

  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
  }

  override func willActivate() {
    super.willActivate()
  }

  override func didDeactivate() {
    super.didDeactivate()
  }

  @IBAction func pressedButton(sender: WKInterfaceButton) {
    incrementLabel(label: label!)
  }

  func incrementLabel(label: WKInterfaceLabel) {
    contents += 1
    label.setText(String(contents))
  }

}
