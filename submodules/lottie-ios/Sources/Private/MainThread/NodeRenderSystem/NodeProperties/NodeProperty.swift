






import CoreGraphics
import Foundation


class NodeProperty<T>: AnyNodeProperty {

  

  init(provider: AnyValueProvider) {
    valueProvider = provider
    originalValueProvider = valueProvider
    typedContainer = ValueContainer<T>(provider.value(frame: 0) as! T)
    typedContainer.setNeedsUpdate()
  }

  

  var valueProvider: AnyValueProvider
  var originalValueProvider: AnyValueProvider

  var valueType: Any.Type { T.self }

  var value: T {
    typedContainer.outputValue
  }

  var valueContainer: AnyValueContainer {
    typedContainer
  }

  func needsUpdate(frame: CGFloat) -> Bool {
    valueContainer.needsUpdate || valueProvider.hasUpdate(frame: frame)
  }

  func setProvider(provider: AnyValueProvider) {
    guard provider.valueType == valueType else { return }
    valueProvider = provider
    valueContainer.setNeedsUpdate()
  }

  func update(frame: CGFloat) {
    typedContainer.setValue(valueProvider.value(frame: frame), forFrame: frame)
  }

  

  fileprivate var typedContainer: ValueContainer<T>
}
