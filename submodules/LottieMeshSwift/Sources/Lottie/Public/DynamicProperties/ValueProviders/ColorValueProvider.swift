






import Foundation
import CoreGraphics


public final class ColorValueProvider: AnyValueProvider {
  
  
  public typealias ColorValueBlock = (CGFloat) -> Color
  
  
  public var color: Color {
    didSet {
      hasUpdate = true
    }
  }
  
  
  public init(block: @escaping ColorValueBlock) {
    self.block = block
    self.color = Color(r: 0, g: 0, b: 0, a: 1)
  }
  
  
  public init(_ color: Color) {
    self.color = color
    self.block = nil
    hasUpdate = true
  }
  
  
  
  public var valueType: Any.Type {
    return Color.self
  }
  
  public func hasUpdate(frame: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }
  
  public func value(frame: CGFloat) -> Any {
    hasUpdate = false
    let newColor: Color
    if let block = block {
      newColor = block(frame)
    } else {
      newColor = color
    }
    return newColor
  }
  
  
  
  private var hasUpdate: Bool = true
  
  private var block: ColorValueBlock?
}
