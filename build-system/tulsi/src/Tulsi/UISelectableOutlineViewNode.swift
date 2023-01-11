

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa


protocol Selectable: AnyObject {
  var selected: Bool { get set }
}


class UISelectableOutlineViewNode: NSObject {

  
  @objc let name: String

  
  var entry: Selectable? {
    didSet {
      if let entry = entry {
        state = entry.selected ? NSControl.StateValue.on.rawValue : NSControl.StateValue.off.rawValue
      }
    }
  }

  
  @objc var children: [UISelectableOutlineViewNode] {
    return _children
  }
  private var _children = [UISelectableOutlineViewNode]()

  
  weak var parent: UISelectableOutlineViewNode?

  
  @objc dynamic var state: Int {
    get {
      if children.isEmpty {
        return (entry?.selected ?? false) ? NSControl.StateValue.on.rawValue : NSControl.StateValue.off.rawValue
      }

      var stateIsValid = false
      var state = NSControl.StateValue.off
      for node in children {
        if !stateIsValid {
          state = NSControl.StateValue(rawValue: node.state)
          stateIsValid = true
          continue
        }
        if state.rawValue != node.state {
          return NSControl.StateValue.mixed.rawValue
        }
      }
      return state.rawValue
    }

    set {
      let newSelectionState = (newValue == NSControl.StateValue.on.rawValue)
      let selected = entry?.selected
      if selected == newSelectionState {
        return
      }

      willChangeValue(for: \.state)
      if let entry = entry {
        entry.selected = newSelectionState
      }

      for node in children {
        node.state = newValue
      }
      didChangeValue(for: \.state)

      
      var ancestor = parent
      while ancestor != nil {
        ancestor!.willChangeValue(for: \.state)
        ancestor!.didChangeValue(for: \.state)
        ancestor = ancestor!.parent
      }
    }
  }

  init(name: String) {
    self.name = name
    super.init()
  }

  func addChild(_ child: UISelectableOutlineViewNode) {
    _children.append(child)
    child.parent = self
  }

  @objc func validateState(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
    if let value = ioValue.pointee as? NSNumber {
      if value.intValue == NSControl.StateValue.mixed.rawValue {
        ioValue.pointee = NSNumber(value: NSControl.StateValue.on.rawValue as Int)
      }
    }
  }
}
