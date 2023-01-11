






import Foundation
import QuartzCore

protocol NodePropertyMap {
  var properties: [AnyNodeProperty] { get }
}

extension NodePropertyMap {
  
  func needsLocalUpdate(frame: CGFloat) -> Bool {
    for property in properties {
      if property.needsUpdate(frame: frame) {
        return true
      }
    }
    return false
  }
  
  
  func updateNodeProperties(frame: CGFloat) {
    properties.forEach { (property) in
      property.update(frame: frame)
    }
  }
  
}
