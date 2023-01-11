






import Foundation
import QuartzCore


final class SingleValueProvider<ValueType>: AnyValueProvider {
  
  var value: ValueType {
    didSet {
      hasUpdate = true
    }
  }
  
  init(_ value: ValueType) {
    self.value = value
  }
  
  var valueType: Any.Type {
    return ValueType.self
  }
  
  func hasUpdate(frame: CGFloat) -> Bool {
    return hasUpdate
  }
  
  func value(frame: CGFloat) -> Any {
    hasUpdate = false
    return value
  }
  
  private var hasUpdate: Bool = true
}
