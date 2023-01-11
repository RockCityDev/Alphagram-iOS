






import CoreGraphics
import Foundation




protocol AnyNodeProperty {

  
  func needsUpdate(frame: CGFloat) -> Bool

  
  func update(frame: CGFloat)

  
  var valueContainer: AnyValueContainer { get }

  
  var valueProvider: AnyValueProvider { get }

  
  var originalValueProvider: AnyValueProvider { get }

  
  var valueType: Any.Type { get }

  
  func setProvider(provider: AnyValueProvider)
}

extension AnyNodeProperty {

  
  func getValueOfType<T>() -> T? {
    valueContainer.value as? T
  }

  
  func getValue() -> Any? {
    valueContainer.value
  }

}
