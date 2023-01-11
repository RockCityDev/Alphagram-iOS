

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



class BazelSelectionPanel: FilteredOpenPanel {

  
  @IBOutlet weak var bazelSelectorUseAsDefaultCheckbox: NSButton!

  @discardableResult
  static func beginSheetModalBazelSelectionPanelForWindow(_ window: NSWindow,
                                                          document: TulsiProjectDocument,
                                                          completionHandler: ((URL?) -> Void)? = nil) -> BazelSelectionPanel {
    let panel = BazelSelectionPanel()
    panel.delegate = panel
    panel.message = NSLocalizedString("ProjectEditor_SelectBazelPathMessage",
                                      comment: "Message to show at the top of the Bazel selector sheet, explaining what to do.")
    panel.prompt = NSLocalizedString("ProjectEditor_SelectBazelPathPrompt",
                                     comment: "Label for the button used to confirm the selected Bazel file in the Bazel selector sheet.")

    var views: NSArray?
    Bundle.main.loadNibNamed("BazelOpenSheetAccessoryView",
                             owner: panel,
                             topLevelObjects: &views)
    
    
    if let views = views {
      let viewsFound = views.filter() { $0 is NSView } as NSArray
      if let accessoryView = viewsFound.firstObject as? NSView {
        panel.accessoryView = accessoryView
        if #available(OSX 10.11, *) {
          panel.isAccessoryViewDisclosed = true
        }
      } else {
        assertionFailure("Failed to load accessory view for Bazel open sheet.")
      }
    }
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.directoryURL = document.bazelURL?.deletingLastPathComponent()
    panel.beginSheetModal(for: window) { value in
      if value == NSApplication.ModalResponse.OK {
        document.bazelURL = panel.url
        if panel.bazelSelectorUseAsDefaultCheckbox.state == NSControl.StateValue.on {
          UserDefaults.standard.set(document.bazelURL!, forKey: BazelLocator.DefaultBazelURLKey)
        }
      }

      
      
      panel.orderOut(panel)
      if let completionHandler = completionHandler {
        completionHandler(value == NSApplication.ModalResponse.OK ? panel.url : nil)
      }
    }
    return panel
  }
}
