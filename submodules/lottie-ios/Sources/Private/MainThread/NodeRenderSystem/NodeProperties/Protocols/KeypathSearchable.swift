






import Foundation
import QuartzCore


protocol KeypathSearchable {

  
  var keypathName: String { get }

  
  var keypathProperties: [String: AnyNodeProperty] { get }

  
  var childKeypaths: [KeypathSearchable] { get }

  var keypathLayer: CALayer? { get }
}
