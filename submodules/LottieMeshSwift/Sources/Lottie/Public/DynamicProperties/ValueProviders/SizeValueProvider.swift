






import Foundation
import CoreGraphics


public final class SizeValueProvider: AnyValueProvider {
  
  
  public typealias SizeValueBlock = (CGFloat) -> CGSize
  
  public var size: CGSize {
    didSet {
      hasUpdate = true
    }
  }
  
  
  public init(block: @escaping SizeValueBlock) {
    self.block = block
    self.size = .zero
  }
  
  
  public init(_ size: CGSize) {
    self.size = size
    self.block = nil
    hasUpdate = true
  }
  
  
  
  public var valueType: Any.Type {
    return Vector3D.self
  }
  
  public func hasUpdate(frame: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }
  
  public func value(frame: CGFloat) -> Any {
    hasUpdate = false
    let newSize: CGSize
    if let block = block {
      newSize = block(frame)
    } else {
      newSize = size
    }
    return newSize.vector3dValue
  }
  
  
  
  private var hasUpdate: Bool = true
  
  private var block: SizeValueBlock?
}
