






import CoreGraphics
import Foundation


public final class ColorValueProvider: ValueProvider {

  

  
  public init(block: @escaping ColorValueBlock) {
    self.block = block
    color = Color(r: 0, g: 0, b: 0, a: 1)
    keyframes = nil
  }

  
  public init(_ color: Color) {
    self.color = color
    block = nil
    keyframes = nil
    hasUpdate = true
  }

  
  public init(_ keyframes: [Keyframe<Color>]) {
    self.keyframes = keyframes
    color = Color(r: 0, g: 0, b: 0, a: 1)
    block = nil
    hasUpdate = true
  }

  

  
  public typealias ColorValueBlock = (CGFloat) -> Color

  
  public var color: Color {
    didSet {
      hasUpdate = true
    }
  }

  

  public var valueType: Any.Type {
    Color.self
  }

  public var storage: ValueProviderStorage<Color> {
    if let block = block {
      return .closure { frame in
        self.hasUpdate = false
        return block(frame)
      }
    } else if let keyframes = keyframes {
      return .keyframes(keyframes)
    } else {
      hasUpdate = false
      return .singleValue(color)
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil {
      return true
    }
    return hasUpdate
  }

  

  private var hasUpdate = true

  private var block: ColorValueBlock?
  private var keyframes: [Keyframe<Color>]?
}
