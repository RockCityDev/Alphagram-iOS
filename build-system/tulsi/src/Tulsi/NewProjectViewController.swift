

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



protocol NewProjectViewControllerDelegate: AnyObject {
  func viewController(_ vc: NewProjectViewController,
                      didCompleteWithReason: NewProjectViewController.CompletionReason)
}



final class NewProjectViewController: NSViewController {
  
  enum CompletionReason {
    case cancel, create
  }

  @objc dynamic var projectName: String? = nil
  @objc dynamic var workspacePath: URL? = nil

  weak var delegate: NewProjectViewControllerDelegate?

  @IBAction func didClickCancelButton(_ sender: NSButton) {
    delegate?.viewController(self, didCompleteWithReason: .cancel)
  }

  @IBAction func didClickNextButton(_ sender: NSButton) {
    self.delegate?.viewController(self, didCompleteWithReason: .create)
  }

  @IBAction func didClickWorkspacePathControl(_ sender: NSPathControl) {
    if let clickedCell = sender.clickedPathComponentCell() {
      
      sender.url = clickedCell.url
    } else {
      // The user clicked on the "Choose..." placeholder; treat this as a double click.
      didDoubleClickWorkspacePathControl(sender)
    }
  }

  @IBAction func didDoubleClickWorkspacePathControl(_ sender: NSPathControl) {
    let panel = FilteredOpenPanel.filteredOpenPanelAcceptingNonPackageDirectoriesAndFilesNamed(["WORKSPACE"])
    if let clickedCell = sender.clickedPathComponentCell() {
      panel.directoryURL = clickedCell.url
    }

    panel.message = NSLocalizedString("NewProject_SetProjectWorkspaceMessage",
                                      comment: "Message to show at the top of WORKSPACE file selector sheet, explaining what to do.")
    panel.prompt = NSLocalizedString("NewProject_SetProjectWorkspacePrompt",
                                     comment: "Label for the button used to confirm the selected WORKSPACE.")

    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.beginSheetModal(for: self.view.window!) { value in
      if value == NSApplication.ModalResponse.OK {
        self.workspacePath = panel.url
      }
    }
  }
}
