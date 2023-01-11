

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import TulsiGenerator



class UIRuleInfo: NSObject, Selectable {
  @objc dynamic var targetName: String? {
    return ruleInfo.label.targetName
  }

  @objc dynamic var type: String {
    return ruleInfo.type
  }

  @objc dynamic var selected: Bool = false {
    didSet {
      if !selected { return }
      let linkedInfos = linkedRuleInfos.allObjects as! [UIRuleInfo]
      for linkedInfo in linkedInfos {
        linkedInfo.selected = true
      }
    }
  }

  var fullLabel: String {
    return ruleInfo.label.value
  }

  let ruleInfo: RuleInfo

  
  private var linkedRuleInfos = NSHashTable<AnyObject>.weakObjects()

  init(ruleInfo: RuleInfo) {
    self.ruleInfo = ruleInfo
  }

  func resolveLinkages(_ ruleInfoMap: [BuildLabel: UIRuleInfo]) {
    for label in ruleInfo.linkedTargetLabels {
      guard let linkedUIRuleInfo = ruleInfoMap[label] else { continue }
      linkedRuleInfos.add(linkedUIRuleInfo)
    }
  }
}
