

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



class OptionsTargetNode: UISelectableOutlineViewNode {

  
  @objc var toolTip: String? = nil

  @objc var boldFont: Bool {
    return !children.isEmpty
  }
}


protocol OptionsTargetSelectorControllerDelegate: AnyObject {
  
  func didSelectOptionsTargetNode(_ node: OptionsTargetNode)
}



class OptionsTargetSelectorController: NSObject, NSOutlineViewDelegate {
  static let projectSectionTitle =
      NSLocalizedString("OptionsTarget_ProjectSectionTitle",
                        comment: "Short header shown before the project in the options editor's target selector.")
  static let targetSectionTitle =
      NSLocalizedString("OptionsTarget_TargetSectionTitle",
                        comment: "Short header shown before the build targets in the options editor's target selector.")

  weak var view: NSOutlineView!
  @objc dynamic var nodes = [OptionsTargetNode]()

  weak var delegate: OptionsTargetSelectorControllerDelegate?
  weak var model: OptionsEditorModelProtocol! = nil {
    didSet {
      if model == nil || model.projectName == nil { return }

      let projectSection = OptionsTargetNode(name: OptionsTargetSelectorController.projectSectionTitle)
      projectSection.addChild(OptionsTargetNode(name: model.projectName!))
      var newNodes = [projectSection]

      if model.shouldShowPerTargetOptions, let targetEntries = model.optionsTargetUIRuleEntries {
        let targetSection = OptionsTargetNode(name: OptionsTargetSelectorController.targetSectionTitle)
        for entry in targetEntries {
          let node = OptionsTargetNode(name: entry.targetName!)
          node.toolTip = entry.fullLabel
          node.entry = entry
          targetSection.addChild(node)
        }
        newNodes.append(targetSection)
      }
      nodes = newNodes

      
      view.expandItem(nil, expandChildren: true)
      view.selectRowIndexes(IndexSet(integer: 1), byExtendingSelection: false)
    }
  }

  init(view: NSOutlineView, delegate: OptionsTargetSelectorControllerDelegate) {
    self.view = view
    self.delegate = delegate
    super.init()
    self.view.delegate = self
  }

  func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
    
    return outlineView.level(forItem: item) > 0
  }

  func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
    return false
  }

  func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
    return false
  }

  func outlineViewSelectionDidChange(_ notification: Notification) {
    if delegate == nil { return }
    let selectedTreeNode = view.item(atRow: view.selectedRow) as! NSTreeNode
    let selectedTarget = selectedTreeNode.representedObject as! OptionsTargetNode
    delegate!.didSelectOptionsTargetNode(selectedTarget)
  }
}
