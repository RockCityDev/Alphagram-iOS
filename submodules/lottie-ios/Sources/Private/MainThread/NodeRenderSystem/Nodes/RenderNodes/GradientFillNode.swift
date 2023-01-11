






import Foundation
import QuartzCore



final class GradientFillProperties: NodePropertyMap, KeypathSearchable {

  

  init(gradientfill: GradientFill) {
    keypathName = gradientfill.name
    opacity = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientfill.opacity.keyframes))
    startPoint = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientfill.startPoint.keyframes))
    endPoint = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientfill.endPoint.keyframes))
    colors = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientfill.colors.keyframes))
    gradientType = gradientfill.gradientType
    numberOfColors = gradientfill.numberOfColors
    keypathProperties = [
      "Opacity" : opacity,
      "Start Point" : startPoint,
      "End Point" : endPoint,
      "Colors" : colors,
    ]
    properties = Array(keypathProperties.values)
  }

  

  var keypathName: String

  let opacity: NodeProperty<Vector1D>
  let startPoint: NodeProperty<Vector3D>
  let endPoint: NodeProperty<Vector3D>
  let colors: NodeProperty<[Double]>

  let gradientType: GradientType
  let numberOfColors: Int

  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]

}



final class GradientFillNode: AnimatorNode, RenderNode {

  

  init(parentNode: AnimatorNode?, gradientFill: GradientFill) {
    fillRender = GradientFillRenderer(parent: parentNode?.outputNode)
    fillProperties = GradientFillProperties(gradientfill: gradientFill)
    self.parentNode = parentNode
  }

  

  let fillRender: GradientFillRenderer

  let fillProperties: GradientFillProperties

  let parentNode: AnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

  var renderer: NodeOutput & Renderable {
    fillRender
  }

  

  var propertyMap: NodePropertyMap & KeypathSearchable {
    fillProperties
  }

  var isEnabled = true {
    didSet {
      fillRender.isEnabled = isEnabled
    }
  }

  func localUpdatesPermeateDownstream() -> Bool {
    false
  }

  func rebuildOutputs(frame _: CGFloat) {
    fillRender.start = fillProperties.startPoint.value.pointValue
    fillRender.end = fillProperties.endPoint.value.pointValue
    fillRender.opacity = fillProperties.opacity.value.cgFloatValue * 0.01
    fillRender.colors = fillProperties.colors.value.map { CGFloat($0) }
    fillRender.type = fillProperties.gradientType
    fillRender.numberOfColors = fillProperties.numberOfColors
  }
}
