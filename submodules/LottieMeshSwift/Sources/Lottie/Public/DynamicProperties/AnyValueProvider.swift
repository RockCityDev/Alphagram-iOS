






import Foundation
import CoreGraphics


public protocol AnyValueProvider {
  
  
  var valueType: Any.Type { get }
  
  
  func hasUpdate(frame: AnimationFrameTime) -> Bool
  
  
  func value(frame: AnimationFrameTime) -> Any
}
