






import CoreGraphics
import Foundation


public final class FloatValueProvider: ValueProvider {

  

  
  public init(block: @escaping CGFloatValueBlock) {
    self.block = block
    float = 0
  }

  
  public init(_ float: CGFloat) {
    self.float = float
    block = nil
    hasUpdate = true
  }

  

  
  public typealias CGFloatValueBlock = (CGFloat) -> CGFloat

  public var float: CGFloat {
    didSet {
      hasUpdate = true
    }
  }

  

  public var valueType: Any.Type {
    Vector1D.self
  }

  public var storage: ValueProviderStorage<Vector1D> {
    if let block = block {
      return .closure { frame in
        self.hasUpdate = false
        return Vector1D(Double(block(frame)))
      }
    } else {
      hasUpdate = false
      return .singleValue(Vector1D(Double(float)))
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  

  private var hasUpdate = true

  private var block: CGFloatValueBlock?
}
