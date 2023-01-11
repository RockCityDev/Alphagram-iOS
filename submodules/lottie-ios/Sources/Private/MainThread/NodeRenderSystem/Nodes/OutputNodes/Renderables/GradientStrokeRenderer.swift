






import Foundation
import QuartzCore



final class GradientStrokeRenderer: PassThroughOutputNode, Renderable {

  

  override init(parent: NodeOutput?) {
    strokeRender = StrokeRenderer(parent: nil)
    gradientRender = LegacyGradientFillRenderer(parent: nil)
    strokeRender.color = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1, 1, 1, 1])
    super.init(parent: parent)
  }

  

  var shouldRenderInContext = true

  let strokeRender: StrokeRenderer
  let gradientRender: LegacyGradientFillRenderer

  override func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    let updates = super.hasOutputUpdates(forFrame)
    return updates || strokeRender.hasUpdate || gradientRender.hasUpdate
  }

  func updateShapeLayer(layer _: CAShapeLayer) {
    
  }

  func setupSublayers(layer _: CAShapeLayer) {
    
  }

  func render(_ inContext: CGContext) {
    guard inContext.path != nil && inContext.path!.isEmpty == false else {
      return
    }

    strokeRender.hasUpdate = false
    hasUpdate = false
    gradientRender.hasUpdate = false

    strokeRender.setupForStroke(inContext)

    inContext.replacePathWithStrokedPath()

    
    gradientRender.render(inContext)

  }

  func renderBoundsFor(_ boundingBox: CGRect) -> CGRect {
    strokeRender.renderBoundsFor(boundingBox)
  }

}
