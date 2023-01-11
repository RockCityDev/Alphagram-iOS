

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



final class TulsiDocumentController: NSDocumentController {

  override func runModalOpenPanel(_ openPanel: NSOpenPanel, forTypes types: [String]?) -> Int {
    openPanel.message = NSLocalizedString("OpenProject_OpenProjectPanelMessage",
                                          comment: "Message to show at the top of tulsiproj open panel, explaining what to do.")
    return super.runModalOpenPanel(openPanel, forTypes: types)
  }
}
