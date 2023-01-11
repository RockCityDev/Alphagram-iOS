

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



final class OptionsEditorViewController: NSViewController, NSSplitViewDelegate, OptionsTargetSelectorControllerDelegate {

  @IBOutlet weak var targetSelectorView: NSOutlineView!
  @IBOutlet weak var optionEditorView: NSOutlineView!

  @objc dynamic var targetSelectorController: OptionsTargetSelectorController? = nil
  @objc dynamic var editorController: OptionsEditorController? = nil

  override var representedObject: Any? {
    didSet {
      syncViewsFromModel()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    targetSelectorController = OptionsTargetSelectorController(view: targetSelectorView,
                                                               delegate: self)
    editorController = OptionsEditorController(view: optionEditorView, storyboard: storyboard!)
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    syncViewsFromModel()
  }

  @IBAction func textFieldDidCompleteEditing(_ sender: OptionsEditorTextField) {
    editorController?.stringBasedControlDidCompleteEditing(sender)
  }

  @IBAction func popUpFieldDidCompleteEditing(_ sender: NSPopUpButton) {
    editorController?.popUpFieldDidCompleteEditing(sender)
  }

  @IBAction func didDoubleClickInEditorView(_ sender: NSOutlineView) {
    editorController?.didDoubleClickInEditorView(sender)
  }

  

  func splitView(_ splitView: NSSplitView,
                 constrainMinCoordinate proposedMinimumPosition: CGFloat,
                 ofSubviewAt dividerIndex: Int) -> CGFloat {
    
    let minWidth = targetSelectorView.tableColumns[0].minWidth + targetSelectorView.intercellSpacing.width
    return minWidth
  }

  

  func didSelectOptionsTargetNode(_ selectedTarget: OptionsTargetNode) {
    editorController?.prepareEditorForTarget(selectedTarget.entry as? UIRuleInfo)
  }

  

  private func syncViewsFromModel() {
    guard let model = representedObject as? OptionsEditorModelProtocol else { return }

    
    
    editorController?.model = model
    targetSelectorController?.model = model
  }
}
