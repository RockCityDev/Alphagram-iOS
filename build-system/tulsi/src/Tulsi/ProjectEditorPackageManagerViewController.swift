

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



final class ProjectEditorPackageManagerViewController: NSViewController, NewProjectViewControllerDelegate {

  
  private enum SegmentedControlButtonIndex: Int {
    case add = 0
    case remove = 1
  }

  @IBOutlet var packageArrayController: NSArrayController!
  @IBOutlet weak var addRemoveSegmentedControl: NSSegmentedControl!

  var newProjectSheet: NewProjectViewController! = nil
  private var newProjectNeedsSaveAs = false

  @objc dynamic var numSelectedPackagePaths: Int = 0 {
    didSet {
      let enableRemoveButton = numSelectedPackagePaths > 0
      addRemoveSegmentedControl.setEnabled(enableRemoveButton,
                                           forSegment: SegmentedControlButtonIndex.remove.rawValue)
    }
  }

  deinit {
    NSObject.unbind(NSBindingName(rawValue: "numSelectedPackagePaths"))
  }

  override func loadView() {
    ValueTransformer.setValueTransformer(PackagePathValueTransformer(),
                                           forName: NSValueTransformerName(rawValue: "PackagePathValueTransformer"))
    super.loadView()
    bind(NSBindingName(rawValue: "numSelectedPackagePaths"),
         to: packageArrayController!,
         withKeyPath: "selectedObjects.@count",
         options: nil)
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    let document = representedObject as! TulsiProjectDocument

    
    if document.fileURL != nil || document.project != nil { return }
    newProjectSheet = NewProjectViewController()
    newProjectSheet.delegate = self

    
    
    
    DispatchQueue.main.async(execute: {
      self.presentAsSheet(self.newProjectSheet)
    })
  }

  @IBAction func didClickAddRemoveSegmentedControl(_ sender: NSSegmentedCell) {
    
    if sender.selectedSegment < 0 { return }

    guard let button = SegmentedControlButtonIndex(rawValue: sender.selectedSegment) else {
      assertionFailure("Unexpected add/remove button index \(sender.selectedSegment)")
      return
    }

    switch button {
      case .add:
        didClickAddBUILDFile(sender)
      case .remove:
        didClickRemoveSelectedBUILDFiles(sender)
    }
  }

  func didClickAddBUILDFile(_ sender: AnyObject?) {
    guard let document = self.representedObject as? TulsiProjectDocument,
              let workspacePath = document.workspaceRootURL?.path else {
      return
    }

    let panel = FilteredOpenPanel.filteredOpenPanel() {
      (_: AnyObject, url: URL) -> Bool in
        var isDir: AnyObject?
        var isPackage: AnyObject?
        do {
          try (url as NSURL).getResourceValue(&isDir, forKey: URLResourceKey.isDirectoryKey)
          try (url as NSURL).getResourceValue(&isPackage, forKey: URLResourceKey.isPackageKey)
          if let isDir = isDir as? NSNumber, let isPackage = isPackage as? NSNumber, !isPackage.boolValue {
            if isDir.boolValue { return true }
            let filename = url.lastPathComponent
            if filename == "BUILD" || filename == "BUILD.bazel" {
              
              return url.path.hasPrefix(workspacePath) && !document.containsBUILDFileURL(url)
            }
          }
        } catch _ {
          
        }
        return false
    }

    panel.prompt = NSLocalizedString("ProjectEditor_AddBUILDFilePrompt",
                                     comment: "Label for the button used to confirm adding the selected BUILD file to the Tulsi project.")
    panel.canChooseDirectories = false
    panel.beginSheetModal(for: self.view.window!) { value in
      if value == NSApplication.ModalResponse.OK {
        guard let URL = panel.url else {
          return
        }
        if !document.addBUILDFileURL(URL) {
          NSSound.beep()
        }
      }
    }
  }

  func didClickRemoveSelectedBUILDFiles(_ sender: AnyObject?) {
    let document = representedObject as! TulsiProjectDocument
    if document.hasChildConfigDocuments {
      let alert = NSAlert()
      alert.messageText = NSLocalizedString("ProjectEditor_CloseOpenedConfigDocumentsMessage",
                                            comment: "Message asking the user if they want to continue with an operation that requires that all opened TulsiGeneratorConfig documents be closed.")
      alert.addButton(withTitle: NSLocalizedString("ProjectEditor_CloseOpenedConfigDocumentsButtonOK",
                                                 comment: "Title for a button that will proceed with an operation that requires that all opened TulsiGeneratorConfig documents be closed."))
      alert.addButton(withTitle: NSLocalizedString("ProjectEditor_CloseOpenedConfigDocumentsButtonCancel",
                                                 comment: "Title for a button that will cancel an operation that requires that all opened TulsiGeneratorConfig documents be closed."))
      alert.beginSheetModal(for: self.view.window!) { value in
        if value == NSApplication.ModalResponse.alertFirstButtonReturn {
          document.closeChildConfigDocuments()
          self.didClickRemoveSelectedBUILDFiles(sender)
        }
      }
      return
    }

    packageArrayController.remove(atArrangedObjectIndexes: packageArrayController.selectionIndexes)
    let remainingObjects = packageArrayController.arrangedObjects as! [String]
    document.bazelPackages = remainingObjects
  }

  @IBAction func selectBazelPath(_ sender: AnyObject?) {
    let document = representedObject as! TulsiProjectDocument
    BazelSelectionPanel.beginSheetModalBazelSelectionPanelForWindow(self.view.window!,
                                                                    document: document)
  }

  @IBAction func didDoubleClickPackage(_ sender: NSTableView) {
    let clickedRow = sender.clickedRow
    guard clickedRow >= 0 else { return }
    let package = (packageArrayController.arrangedObjects as! [String])[clickedRow]
    let document = representedObject as! TulsiProjectDocument
    let buildFile = package + "/BUILD"
    if let url = document.workspaceRootURL?.appendingPathComponent(buildFile) {
      NSWorkspace.shared.open(url)
    }
  }

  func document(_ document: NSDocument, didSave: Bool, contextInfo: AnyObject) {
    if !didSave {
      
      self.view.window!.close()
      return
    }
  }

  

  func viewController(_ vc: NewProjectViewController,
                      didCompleteWithReason reason: NewProjectViewController.CompletionReason) {
    defer {newProjectSheet = nil}
    dismiss(vc)

    guard reason == .create else {
      
      
      self.view.window!.close()
      return
    }

    let document = representedObject as! TulsiProjectDocument
    document.createNewProject(newProjectSheet.projectName!,
                              workspaceFileURL: newProjectSheet.workspacePath!)
    newProjectNeedsSaveAs = true
  }
}




final class PackagePathValueTransformer : ValueTransformer {
  override class func transformedValueClass() -> AnyClass {
    return NSString.self
  }

  override class func allowsReverseTransformation() -> Bool  {
    return false
  }

  override func transformedValue(_ value: Any?) -> Any? {
    guard let value = value as? String else { return nil }
    return "//\(value)"
  }
}
