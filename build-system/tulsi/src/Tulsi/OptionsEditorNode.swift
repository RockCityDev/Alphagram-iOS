

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



class OptionsEditorNode: NSObject {
  
  enum OptionLevel: String {
    case Target = "TargetValue"
    case Project = "ProjectValue"
    case Default = "DefaultValue"
  }

  @objc var name: String {
    assertionFailure("Must be overridden by subclasses")
    return "<ERROR>"
  }

  @objc var toolTip: String {
    assertionFailure("Must be overridden by subclasses")
    return ""
  }

  
  var multiSelectItems: [String] {
    assertionFailure("multiSelectItems accessed for options node that is not a multi-select type")
    return []
  }

  
  var supportsMultilineEditor: Bool {
    return true
  }

  
  var mostSpecializedOptionLevel: OptionLevel {
    return .Default
  }

  var valueType: TulsiOption.ValueType {
    assertionFailure("Must be overridden by subclasses")
    return .string
  }

  /// The value to display in the "default" column.
  @objc var defaultValueDisplayItem: String {
    return ""
  }

  
  @objc var children = [OptionsEditorNode]()

  func editableForOptionLevel(_ level: OptionLevel) -> Bool {
    assertionFailure("Must be overridden by subclasses")
    return false
  }

  
  
  func displayItemForOptionLevel(_ level: OptionLevel) -> (displayItem: String, inherited: Bool) {
    assertionFailure("Must be overridden by subclasses")
    return ("", false)
  }

  func setDisplayItem(_ displayItem: String?, forOptionLevel level: OptionLevel) {
    assertionFailure("Must be overridden by subclasses")
  }

  
  
  func deleteMostSpecializedValue() -> Bool {
    if mostSpecializedOptionLevel == .Default { return false }
    removeValueForOptionLevel(mostSpecializedOptionLevel)
    return true
  }

  func removeValueForOptionLevel(_ level: OptionLevel) {
    assertionFailure("Must be overridden by subclasses")
  }

  

  override var debugDescription: String {
    return "\(super.debugDescription) - \(name)"
  }
}



class OptionsEditorGroupNode: OptionsEditorNode {
  let key: TulsiOptionKeyGroup

  @objc override var name: String {
    return displayName
  }
  let displayName: String

  @objc override var toolTip: String {
    return toolTipValue
  }
  let toolTipValue: String

  override var mostSpecializedOptionLevel: OptionLevel {
    var mostSpecializedOptions = Set<OptionLevel>()
    for child in children {
      mostSpecializedOptions.insert(child.mostSpecializedOptionLevel)
    }

    let orderedOptionLevels: [OptionLevel] = [.Target, .Project]
    for level in orderedOptionLevels {
      if mostSpecializedOptions.contains(level) {
        return level
      }
    }
    return .Default
  }

  override var valueType: TulsiOption.ValueType {
    return children.first!.valueType
  }

  override var defaultValueDisplayItem: String {
    return mergedDefaultValueDisplayItem
  }
  var mergedDefaultValueDisplayItem: String = ""

  init(key: TulsiOptionKeyGroup, displayName: String, description: String) {
    self.key = key
    self.displayName = displayName
    self.toolTipValue = description
    super.init()
  }

  func addChildNode(_ node: OptionsEditorNode) {
    if children.isEmpty {
      mergedDefaultValueDisplayItem = node.defaultValueDisplayItem
    }

    children.append(node)
    children.sort() { $0.name < $1.name }

    if node.defaultValueDisplayItem != mergedDefaultValueDisplayItem {
      mergedDefaultValueDisplayItem = NSLocalizedString("OptionsEditor_MultipleValues",
                                                        comment: "String to show in the option editor for group nodes when there are multiple per-config values.")
    }
  }

  override func editableForOptionLevel(_ level: OptionLevel) -> Bool {
    
    return children[0].editableForOptionLevel(level)
  }

  override func displayItemForOptionLevel(_ level: OptionLevel) -> (displayItem: String, inherited: Bool) {
    var valueMap = [String: Bool]()
    for child in children {
      let (displayItem, inherited) = child.displayItemForOptionLevel(level)
      valueMap[displayItem] = inherited
    }
    if valueMap.count == 1 {
      let pair = valueMap.first!
      return (displayItem: pair.key, inherited: pair.value)
    }

    let displayItem = NSLocalizedString("OptionsEditor_MultipleValues",
                                        comment: "String to show in the option editor for group nodes when there are multiple per-config values.")
    // The pseudo "multiple values" item is never explicitly set by the user so it should be
    
    return (displayItem, true)
  }

  override func setDisplayItem(_ displayItem: String?, forOptionLevel level: OptionLevel) {
    for child in children {
      child.setDisplayItem(displayItem, forOptionLevel: level)
    }
  }

  override func removeValueForOptionLevel(_ level: OptionLevel) {
    for child in children {
      child.removeValueForOptionLevel(level)
    }
  }
}



class OptionsEditorStringNode: OptionsEditorNode {
  let key: TulsiOptionKey
  let option: TulsiOption
  let model: OptionsEditorModelProtocol?

  
  let target: UIRuleInfo?

  @objc override var name: String {
    return option.displayName
  }

  @objc override var toolTip: String {
    return option.userDescription
  }

  override var valueType: TulsiOption.ValueType {
    return option.valueType
  }

  override var defaultValueDisplayItem: String {
    if let parentOption = model?.parentOptionForOptionKey(key) {
      if let value = parentOption.commonValue ?? parentOption.defaultValue {
        return displayItemForValue(value)
      }
    } else if let value = option.defaultValue {
      return displayItemForValue(value)
    }
    return NSLocalizedString("OptionsEditor_NoDefault",
                             comment: "String to show in the options editor's 'default' column when there is no default value.")
  }

  override var mostSpecializedOptionLevel: OptionLevel {
    if let targetLabel = target?.fullLabel, option.targetValues?[targetLabel] != nil {
      return .Target
    }

    if option.projectValue != nil {
      return .Project
    }

    return .Default
  }

  init(key: TulsiOptionKey, option: TulsiOption, model: OptionsEditorModelProtocol?, target: UIRuleInfo?) {
    self.key = key
    self.option = option
    self.model = model
    self.target = target
    super.init()
  }

  func displayItemForValue(_ value: String?) -> String {
    if value == nil { return "" }
    return value!
  }

  func valueForDisplayItem(_ item: String?) -> String {
    if item == nil { return "" }
    return item!
  }

  override func setDisplayItem(_ displayItem: String?, forOptionLevel level: OptionLevel) {
    let sanitizedValue = option.sanitizeValue(valueForDisplayItem(displayItem))
    let value: String?
    
    if sanitizedValue == (mostSpecializedValueBeneathLevel(level) ?? "") {
      value = nil
    } else {
      value = sanitizedValue
    }

    switch(level) {
      case .Target:
        guard let targetLabel = target?.fullLabel else {
          assertionFailure("Attempt to edit target option value but no target is set")
          return
        }
        if option.targetValues == nil {
          assertionFailure("Attempt to edit target option value but option does not support target specialization")
          return
        }
        option.targetValues![targetLabel] = value
        model?.updateChangeCount(.changeDone)

      case .Project:
        option.projectValue = value
        model?.updateChangeCount(.changeDone)

      default:
        assertionFailure("Editor node accessed via unknown subscript \(level)")
        return
    }
  }

  override func displayItemForOptionLevel(_ level: OptionLevel) -> (displayItem: String, inherited: Bool) {
    let (value, inherited) = valueForOptionLevel(level)
    return (displayItemForValue(value), inherited)
  }

  override func removeValueForOptionLevel(_ level: OptionLevel) {
    switch level {
      case .Default:
        return

      case .Target:
        _ = option.targetValues?.removeValue(forKey: target!.fullLabel)
        model?.updateChangeCount(.changeDone)

      case .Project:
        option.projectValue = nil
        model?.updateChangeCount(.changeDone)
    }
  }

  override func editableForOptionLevel(_ level: OptionLevel) -> Bool {
    if level == .Target {
      return option.targetValues != nil
    }
    return true
  }

  

  private func valueForOptionLevel(_ level: OptionLevel) -> (value: String?, inherited: Bool) {
    if level == .Target,
       let targetLabel = target?.fullLabel,
           let value = option.valueForTarget(targetLabel, inherit: false) {
      return (value, false)
    }

    if level == .Target || level == .Project,
       let value = option.projectValue {
      return (value, level != .Project)
    }

    return (option.defaultValue, true)
  }

  private func mostSpecializedValueBeneathLevel(_ level: OptionLevel) -> String? {
    if level == .Target, let value = option.projectValue {
      return value
    }

    return option.defaultValue
  }
}


class OptionsEditorConstrainedStringNode: OptionsEditorStringNode {

  override var supportsMultilineEditor: Bool {
    return false
  }

  override var multiSelectItems: [String] {
    if case .stringEnum(let values) = valueType {
      return Array(values)
    }
    return []
  }
}



class OptionsEditorBooleanNode: OptionsEditorStringNode {
  static let trueDisplayString =
      NSLocalizedString("OptionsEditor_TrueValue",
                        comment: "Value to show when a boolean option is 'true'. This should match Xcode's localization.")
  static let falseDisplayString =
      NSLocalizedString("OptionsEditor_FalseValue",
                        comment: "Value to show when a boolean option is 'false'. This should match Xcode's localization.")

  
  static let booleanOptionValues = [
      OptionsEditorBooleanNode.trueDisplayString,
      OptionsEditorBooleanNode.falseDisplayString
  ]

  override var supportsMultilineEditor: Bool {
    return false
  }

  override var multiSelectItems: [String] {
    return OptionsEditorBooleanNode.booleanOptionValues
  }

  override func displayItemForValue(_ value: String?) -> String {
    if value == TulsiOption.BooleanTrueValue {
      return OptionsEditorBooleanNode.booleanOptionValues[0]
    }
    return OptionsEditorBooleanNode.booleanOptionValues[1]
  }

  override func valueForDisplayItem(_ item: String?) -> String {
    assert(item != nil, "Display item for boolean option node unexpectedly nil")
    if item == nil { return TulsiOption.BooleanFalseValue }

    switch item! {
      case OptionsEditorBooleanNode.trueDisplayString:
        return TulsiOption.BooleanTrueValue

      case OptionsEditorBooleanNode.falseDisplayString:
        return TulsiOption.BooleanFalseValue

      default:
        assertionFailure("Display item for boolean option set to unexpected value \(item!)")
        return TulsiOption.BooleanFalseValue
    }
  }
}
