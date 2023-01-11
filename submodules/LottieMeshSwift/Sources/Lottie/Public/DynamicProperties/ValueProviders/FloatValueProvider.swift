






import Foundation
import CoreGraphics


public final class FloatValueProvider: AnyValueProvider {
  
  
  public typealias CGFloatValueBlock = (CGFloat) -> CGFloat
  
  public var float: CGFloat {
    didSet {
      hasUpdate = true
    }
  }
  
  
  public init(block: @escaping CGFloatValueBlock) {
    self.block = block
    self.float = 0
  }
  
  
  public init(_ float: CGFloat) {
    self.float = float
    self.block = nil
    hasUpdate = true
  }
  
  
  
  public var valueType: Any.Type {
    return Vector1D.self
  }
  
  public func hasUpdate(frame: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }
  
  public func value(frame: CGFloat) -> Any {
    hasUpdate = false
    let newCGFloat: CGFloat
    if let block = block {
      newCGFloat = block(frame)
    } else {
      newCGFloat = float
    }
    return Vector1D(Double(newCGFloat))
  }
  
  
  
  private var hasUpdate: Bool = true
  
  private var block: CGFloatValueBlock?
}

