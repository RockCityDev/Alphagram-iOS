






import Foundation
import CoreGraphics


class ValueContainer<T>: AnyValueContainer {
  
  private(set) var lastUpdateFrame: CGFloat = CGFloat.infinity
  
  func setValue(_ value: Any, forFrame: CGFloat) {
    if let typedValue = value as? T {
      needsUpdate = false
      lastUpdateFrame = forFrame
      outputValue = typedValue
    }
  }
  
  func setNeedsUpdate() {
    needsUpdate = true
  }
  
  var value: Any {
    return outputValue as Any
  }
  
  var outputValue: T {
    didSet {
      needsUpdate = false
    }
  }
  
  init(_ value: T) {
    self.outputValue = value
  }
  
  fileprivate(set) var needsUpdate: Bool = true
}
