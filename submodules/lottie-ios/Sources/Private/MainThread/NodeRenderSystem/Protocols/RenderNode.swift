






import CoreGraphics
import Foundation
import QuartzCore




protocol RenderNode {
  var renderer: Renderable & NodeOutput { get }
}




protocol Renderable {

  
  var hasUpdate: Bool { get }

  func hasRenderUpdates(_ forFrame: CGFloat) -> Bool

  
  
  
  var shouldRenderInContext: Bool { get }

  
  func updateShapeLayer(layer: CAShapeLayer)

  
  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect

  
  func setupSublayers(layer: CAShapeLayer)

  
  func render(_ inContext: CGContext)
}

extension RenderNode where Self: AnimatorNode {

  var outputNode: NodeOutput {
    renderer
  }

}

extension Renderable {

  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect {
    
    boundingBox
  }

}
