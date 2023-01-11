






import Foundation
import CoreGraphics

public final class PointValueProvider: AnyValueProvider {
  
  
  public typealias PointValueBlock = (CGFloat) -> CGPoint
  
  public var point: CGPoint {
    didSet {
      hasUpdate = true
    }
  }
  
  
  public init(block: @escaping PointValueBlock) {
    self.block = block
    self.point = .zero
  }
  
  
  public init(_ point: CGPoint) {
    self.point = point
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
    let newPoint: CGPoint
    if let block = block {
      newPoint = block(frame)
    } else {
      newPoint = point
    }
    return newPoint.vector3dValue
  }
  
  
  
  private var hasUpdate: Bool = true
  
  private var block: PointValueBlock?
}
