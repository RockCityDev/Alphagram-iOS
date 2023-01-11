

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var label: UILabel?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func pressedButton(sender: UIButton) {
    incrementLabel(label: label!)
  }

  func incrementLabel(label: UILabel) {
    let number = Int((label.text)!)
    label.text = String(number! + 1)
  }

}

