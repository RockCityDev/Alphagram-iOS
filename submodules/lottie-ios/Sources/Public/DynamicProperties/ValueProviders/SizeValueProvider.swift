






import CoreGraphics
import Foundation


public final class SizeValueProvider: ValueProvider {

  

  
  public init(block: @escaping SizeValueBlock) {
    self.block = block
    size = .zero
  }

  
  public init(_ size: CGSize) {
    self.size = size
    block = nil
    hasUpdate = true
  }

  

  
  public typealias SizeValueBlock = (CGFloat) -> CGSize

  public var size: CGSize {
    didSet {
      hasUpdate = true
    }
  }

  

  public var valueType: Any.Type {
    Vector3D.self
  }

  public var storage: ValueProviderStorage<Vector3D> {
    if let block = block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame).vector3dValue
      }
    } else {
      hasUpdate = false
      return .singleValue(size.vector3dValue)
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  

  private var hasUpdate = true

  private var block: SizeValueBlock?
}
