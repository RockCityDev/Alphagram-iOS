






import CoreGraphics
import Foundation


protocol AnyValueContainer: AnyObject {

  
  var value: Any { get }

  
  func setNeedsUpdate()

  
  var needsUpdate: Bool { get }

  
  var lastUpdateFrame: CGFloat { get }

}
