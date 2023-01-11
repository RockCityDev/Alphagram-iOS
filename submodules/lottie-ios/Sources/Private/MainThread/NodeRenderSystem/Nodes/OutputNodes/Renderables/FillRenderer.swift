






import CoreGraphics
import Foundation
import QuartzCore

extension FillRule {
  var cgFillRule: CGPathFillRule {
    switch self {
    case .evenOdd:
      return .evenOdd
    default:
      return .winding
    }
  }

  var caFillRule: CAShapeLayerFillRule {
    switch self {
    case .evenOdd:
      return CAShapeLayerFillRule.evenOdd
    default:
      return CAShapeLayerFillRule.nonZero
    }
  }
}




final class FillRenderer: PassThroughOutputNode, Renderable {
  var shouldRenderInContext = false

  var color: CGColor? {
    didSet {
      hasUpdate = true
    }
  }

  var opacity: CGFloat = 0 {
    didSet {
      hasUpdate = true
    }
  }

  var fillRule: FillRule = .none {
    didSet {
      hasUpdate = true
    }
  }

  func render(_: CGContext) {
    
  }

  func setupSublayers(layer _: CAShapeLayer) {
    
  }

  func updateShapeLayer(layer: CAShapeLayer) {
    layer.fillColor = color
    layer.opacity = Float(opacity)
    layer.fillRule = fillRule.caFillRule
    hasUpdate = false
  }

}
