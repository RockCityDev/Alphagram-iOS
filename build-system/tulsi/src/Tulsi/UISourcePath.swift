

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



class UISourcePath: NSObject, Selectable {
  @objc dynamic let path: String
  @objc dynamic var selected: Bool
  @objc dynamic var recursive: Bool

  init(path: String, selected: Bool = false, recursive: Bool = false) {
    self.path = path
    self.selected = selected
    self.recursive = recursive
  }
}
