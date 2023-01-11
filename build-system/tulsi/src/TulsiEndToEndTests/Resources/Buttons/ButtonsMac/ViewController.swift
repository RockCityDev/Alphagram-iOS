

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa

class ViewController: NSViewController {

  @IBOutlet var countLabel: NSTextField!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func didClick(sender: NSButton) {
    incrementLabel(label: countLabel)
  }

  func incrementLabel(label: NSTextField) {
    let number = Int(label.stringValue)
    label.stringValue = String(number! + 1)
  }

}

