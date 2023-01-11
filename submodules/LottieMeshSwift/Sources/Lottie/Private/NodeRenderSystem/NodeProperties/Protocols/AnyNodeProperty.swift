






import Foundation
import CoreGraphics

protocol AnyNodeProperty {
  
  
  func needsUpdate(frame: CGFloat) -> Bool
  
  
  func update(frame: CGFloat)
  
  
  var valueContainer: AnyValueContainer { get }
  
  
  var valueProvider: AnyValueProvider { get }
  
  
  var valueType: Any.Type { get }
  
  
  func setProvider(provider: AnyValueProvider)
}

extension AnyNodeProperty {

  
  func getValueOfType<T>() -> T? {
    return valueContainer.value as? T
  }
  
  
  func getValue() -> Any? {
    return valueContainer.value
  }

}
