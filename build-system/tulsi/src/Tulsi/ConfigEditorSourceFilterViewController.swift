

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa



final class SourcePathNode: UISelectableOutlineViewNode {

  
  
  @objc dynamic var explicitlyRecursive: Bool {
    return recursive == NSControl.StateValue.on.rawValue
  }

  
  @objc dynamic var recursive: Int {
    get {
      guard let entry = entry as? UISourcePath else { return NSControl.StateValue.off.rawValue }
      if entry.recursive { return NSControl.StateValue.on.rawValue }

      for child in children as! [SourcePathNode] {
        if child.recursive != NSControl.StateValue.off.rawValue {
          return NSControl.StateValue.mixed.rawValue
        }
      }
      return NSControl.StateValue.off.rawValue
    }

    set {
      
      if newValue == NSControl.StateValue.mixed.rawValue { return }

      guard let entry = entry as? UISourcePath else { return }
      let enabled = newValue == NSControl.StateValue.on.rawValue
      willChangeValue(for: \.explicitlyRecursive)
      entry.recursive = enabled
      didChangeValue(for: \.explicitlyRecursive)

      
      
      setChildrenHaveRecursiveParent(enabled || hasRecursiveEnabledParent)

      
      var child: SourcePathNode? = self
      while let parent = child?.parent as? SourcePathNode {
        parent.willChangeValue(for: \.recursive)
        parent.didChangeValue(for: \.recursive)
        child = parent
      }
    }
  }

  @objc dynamic var hasRecursiveEnabledParent: Bool = false {
    willSet {
      
      
      if recursive == NSControl.StateValue.on.rawValue || newValue == hasRecursiveEnabledParent { return }
      setChildrenHaveRecursiveParent(newValue)
    }
  }

  @objc func validateRecursive(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
    if let value = ioValue.pointee as? NSNumber {
      if value.intValue == NSControl.StateValue.mixed.rawValue {
        ioValue.pointee = NSNumber(value: NSControl.StateValue.on.rawValue as Int)
      }
    }
  }

  

  fileprivate func setChildrenHaveRecursiveParent(_ newValue: Bool) {
    for child in children as! [SourcePathNode] {
      child.hasRecursiveEnabledParent = newValue
      
      
      if newValue {
        child.recursive = NSControl.StateValue.off.rawValue
      }
    }
  }
}




final class ConfigEditorSourceFilterViewController: NSViewController, WizardSubviewProtocol {
  @objc dynamic var sourceFilterContentArray: [SourcePathNode] = []
  @IBOutlet weak var sourceFilterOutlineView: NSOutlineView!

  override func viewDidLoad() {
    super.viewDidLoad()
    let sourceTargetColumn = sourceFilterOutlineView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "sourceTargets"))!
    sourceFilterOutlineView.sortDescriptors = [sourceTargetColumn.sortDescriptorPrototype!]
  }

  

  weak var presentingWizardViewController: ConfigEditorWizardViewController? = nil

  func wizardSubviewWillActivateMovingForward() {
    let document = representedObject as! TulsiGeneratorConfigDocument
    sourceFilterContentArray = []
    document.updateSourcePaths(populateOutlineView)

    document.updateChangeCount(.changeDone)
  }

  

  private func populateOutlineView(_ sourcePaths: [UISourcePath]) {
    
    let componentDelimiters = CharacterSet(charactersIn: "/:")
    let splitSourcePaths = sourcePaths.map() {
      $0.path.components(separatedBy: componentDelimiters)
    }

    var recursiveNodes = [SourcePathNode]()

    let topNode = SourcePathNode(name: "")
    for i in 0 ..< splitSourcePaths.count {
      let label = splitSourcePaths[i]
      var node = topNode
      elementLoop: for element in label {
        if element == "" {
          continue
        }
        for child in node.children as! [SourcePathNode] {
          if child.name == element {
            node = child
            continue elementLoop
          }
        }
        let newNode = SourcePathNode(name: element)
        node.addChild(newNode)
        node = newNode
      }
      node.entry = sourcePaths[i]
      if node.recursive == NSControl.StateValue.on.rawValue {
        recursiveNodes.append(node)
      }
    }

    
    for node in recursiveNodes {
      node.setChildrenHaveRecursiveParent(true)
    }

    sourceFilterContentArray = topNode.children as! [SourcePathNode]
  }
}
