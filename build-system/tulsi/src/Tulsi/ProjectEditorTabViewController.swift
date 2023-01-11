

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



final class ProjectTabViewController: NSTabViewController {

  override var representedObject: Any? {
    didSet {
      for vc in children {
        vc.representedObject = representedObject
      }
    }
  }
}
