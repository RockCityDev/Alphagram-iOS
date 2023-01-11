

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa




final class ConfigEditorBuildTargetSelectorViewController: NSViewController, WizardSubviewProtocol {
  
  
  
  
  // generates all targets referenced in an ios_application's "extensions" attribute rather than
  
  
  static let filteredFileTypes = [
      
      
      "apple_ui_test",
      "apple_unit_test",
      "cc_binary",
      "cc_library",
      "cc_test",
      "ios_app_clip",
      "ios_application",
      "ios_framework",
      "ios_static_framework",
      "ios_legacy_test",
      "ios_ui_test",
      "ios_unit_test",
      "macos_application",
      "macos_bundle",
      "macos_command_line_application",
      "macos_extension",
      "macos_ui_test",
      "macos_unit_test",
      "objc_library",
      "swift_library",
      "test_suite",
      "tvos_application",
      "tvos_ui_test",
      "tvos_unit_test",
  ]

  @IBOutlet weak var buildTargetTable: NSTableView!

  @objc dynamic let typeFilter: NSPredicate? = NSPredicate.init(format: "(SELF.type IN %@) OR (SELF.selected == TRUE)",
                                                          argumentArray: [filteredFileTypes])

  @objc var selectedRuleInfoCount: Int = 0 {
    didSet {
      presentingWizardViewController?.setNextButtonEnabled(selectedRuleInfoCount > 0)
    }
  }

  override var representedObject: Any? {
    didSet {
      NSObject.unbind(NSBindingName(rawValue: "selectedRuleInfoCount"))
      guard let document = representedObject as? TulsiGeneratorConfigDocument else { return }
      bind(NSBindingName(rawValue: "selectedRuleInfoCount"),
           to: document,
           withKeyPath: "selectedRuleInfoCount",
           options: nil)
    }
  }

  deinit {
    NSObject.unbind(NSBindingName(rawValue: "selectedRuleInfoCount"))
  }

  override func loadView() {
    super.loadView()

    let typeColumn = buildTargetTable.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Type"))!
    let labelColumn = buildTargetTable.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Label"))!
    buildTargetTable.sortDescriptors = [typeColumn.sortDescriptorPrototype!,
                                        labelColumn.sortDescriptorPrototype!]
  }

  

  weak var presentingWizardViewController: ConfigEditorWizardViewController? = nil {
    didSet {
      presentingWizardViewController?.setNextButtonEnabled(selectedRuleInfoCount > 0)
    }
  }

  func wizardSubviewDidDeactivate() {
    NSObject.unbind(NSBindingName(rawValue: "selectedRuleInfoCount"))
  }
}
