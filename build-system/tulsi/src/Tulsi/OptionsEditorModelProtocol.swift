

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator



protocol OptionsEditorModelProtocol: AnyObject {
  
  var projectName: String? { get }

  
  var optionSet: TulsiOptionSet? { get }

  
  var optionsTargetUIRuleEntries: [UIRuleInfo]? { get }

  
  var projectValueColumnTitle: String { get }

  
  
  var defaultValueColumnTitle: String { get }

  
  
  func parentOptionForOptionKey(_ key: TulsiOptionKey) -> TulsiOption?

  
  func updateChangeCount(_ change: NSDocument.ChangeType)
}

extension OptionsEditorModelProtocol {

  
  var shouldShowPerTargetOptions: Bool {
    return optionsTargetUIRuleEntries != nil
  }

  
  func parentOptionForOptionKey(_: TulsiOptionKey) -> TulsiOption? {
    return nil
  }
}
