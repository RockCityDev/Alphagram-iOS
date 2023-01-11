

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



protocol NewGeneratorConfigViewControllerDelegate: AnyObject {
  func viewController(_ vc: NewGeneratorConfigViewController,
                      didCompleteWithReason: NewGeneratorConfigViewController.CompletionReason)
}



final class NewGeneratorConfigViewController: NSViewController {

  
  enum CompletionReason {
    case cancel, create
  }

  weak var delegate: NewGeneratorConfigViewControllerDelegate?

  @objc dynamic var configName: String? = nil

  @IBAction func didClickCancelButton(_ sender: NSButton) {
    delegate?.viewController(self, didCompleteWithReason: .cancel)
  }

  @IBAction func didClickSaveButton(_ sender: NSButton) {
    self.delegate?.viewController(self, didCompleteWithReason: .create)
  }
}
