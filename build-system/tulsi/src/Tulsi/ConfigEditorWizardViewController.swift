

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



final class ConfigEditorWizardViewController: NSViewController, NSPageControllerDelegate {
  
  static let wizardPageIdentifiers = [
      "BUILDTargetSelect",
      "Options",
      "SourceTargetSelect",
  ]
  static let LastPageIndex = wizardPageIdentifiers.count - 1
  var pageViewController: NSPageController! = nil

  @IBOutlet weak var previousButton: NSButton!
  @IBOutlet weak var nextButton: NSButton!

  override var representedObject: Any? {
    didSet {
      
      pageViewController?.selectedViewController?.representedObject = representedObject
    }
  }

  override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
    if segue.identifier! == "Embed Wizard PageController" {
      pageViewController = (segue.destinationController as! NSPageController)
      pageViewController.arrangedObjects = ConfigEditorWizardViewController.wizardPageIdentifiers
      pageViewController.delegate = self
    }
    super.prepare(for: segue, sender: sender)
  }

  func setNextButtonEnabled(_ enabled: Bool) {
    nextButton.isEnabled = enabled
  }

  func updateNextButton() {
    if pageViewController.selectedIndex == 0 {
      let document = representedObject as! TulsiGeneratorConfigDocument
      nextButton.isEnabled = document.selectedRuleInfoCount > 0
    }
  }

  @IBAction func cancel(_ sender: AnyObject?) {
    let document = representedObject as! TulsiGeneratorConfigDocument
    do {
      try document.revert()
    } catch {
      
    }
    document.close()
  }

  @IBAction func next(_ sender: NSButton? = nil) {
    if let deactivatingSubview = pageViewController.selectedViewController as? WizardSubviewProtocol, deactivatingSubview.shouldWizardSubviewDeactivateMovingForward?() == false {
      return
    }

    var selectedIndex = pageViewController.selectedIndex
    if selectedIndex >= ConfigEditorWizardViewController.LastPageIndex {
      let document = representedObject as! TulsiGeneratorConfigDocument
      document.save() { (canceled, error) in
        if !canceled && error == nil {
          document.close()
        }
      }
      return
    }

    pageViewController!.navigateForward(sender)
    selectedIndex += 1
    previousButton.isHidden = false

    if selectedIndex == ConfigEditorWizardViewController.LastPageIndex {
      nextButton.title = NSLocalizedString("Wizard_SaveConfig",
                                           comment: "Label for action button to be used to go to the final page in the project wizard.")
    }
  }

  @IBAction func previous(_ sender: NSButton? = nil) {
    if let deactivatingSubview = pageViewController.selectedViewController as? WizardSubviewProtocol, deactivatingSubview.shouldWizardSubviewDeactivateMovingBackward?() == false {
      return
    }

    var selectedIndex = pageViewController!.selectedIndex
    if selectedIndex > 0 {
      previousButton.isHidden = selectedIndex <= 1
      pageViewController!.navigateBack(sender)
      selectedIndex -= 1
      nextButton.isEnabled = true

      if selectedIndex < ConfigEditorWizardViewController.LastPageIndex {
        nextButton.title = NSLocalizedString("Wizard_Next",
                                             comment: "Label for action button to be used to go to the next page in the project wizard.")
      }
    }
  }

  

  func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
    return object as! NSPageController.ObjectIdentifier
  }

  func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
    let vc = storyboard!.instantiateController(withIdentifier: identifier) as! NSViewController

    
    
    vc.view.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
    return vc
  }

  func pageController(_ pageController: NSPageController,
                      prepare viewController: NSViewController,
                      with object: Any?) {
    _pageController(pageController, prepareViewController: viewController, withObject: object! as AnyObject)
  }

  private func _pageController(_ pageController: NSPageController,
                               prepareViewController viewController: NSViewController,
                               withObject object: AnyObject) {
    
    
    
    viewController.representedObject = representedObject

    
    let newPageIndex = ConfigEditorWizardViewController.wizardPageIdentifiers.firstIndex(of: object as! String)!
    let subview = viewController as? WizardSubviewProtocol
    subview?.presentingWizardViewController = self
    if pageController.selectedIndex < newPageIndex {
      subview?.wizardSubviewWillActivateMovingForward?()
    } else if pageController.selectedIndex > newPageIndex {
      subview?.wizardSubviewWillActivateMovingBackward?()
    }
  }

  func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
    if let subview = pageController.selectedViewController as? WizardSubviewProtocol {
      subview.wizardSubviewDidDeactivate?()
    }
    pageController.completeTransition()
  }
}

