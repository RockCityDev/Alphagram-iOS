






import CoreGraphics
import Foundation

public final class PointValueProvider: ValueProvider {

  

  
  public init(block: @escaping PointValueBlock) {
    self.block = block
    point = .zero
  }

  
  public init(_ point: CGPoint) {
    self.point = point
    block = nil
    hasUpdate = true
  }

  

  
  public typealias PointValueBlock = (CGFloat) -> CGPoint

  public var point: CGPoint {
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
      return .singleValue(point.vector3dValue)
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  

  private var hasUpdate = true

  private var block: PointValueBlock?
}
