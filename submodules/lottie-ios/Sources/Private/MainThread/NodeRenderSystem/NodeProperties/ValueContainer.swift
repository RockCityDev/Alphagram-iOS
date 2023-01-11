






import CoreGraphics
import Foundation


class ValueContainer<T>: AnyValueContainer {

  

  init(_ value: T) {
    outputValue = value
  }

  

  private(set) var lastUpdateFrame = CGFloat.infinity

  fileprivate(set) var needsUpdate = true

  var value: Any {
    outputValue as Any
  }

  var outputValue: T {
    didSet {
      needsUpdate = false
    }
  }

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
}
