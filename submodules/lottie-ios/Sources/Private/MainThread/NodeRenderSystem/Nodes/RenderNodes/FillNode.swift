






import CoreGraphics
import Foundation



final class FillNodeProperties: NodePropertyMap, KeypathSearchable {

  

  init(fill: Fill) {
    keypathName = fill.name
    color = NodeProperty(provider: KeyframeInterpolator(keyframes: fill.color.keyframes))
    opacity = NodeProperty(provider: KeyframeInterpolator(keyframes: fill.opacity.keyframes))
    type = fill.fillRule
    keypathProperties = [
      "Opacity" : opacity,
      PropertyName.color.rawValue : color,
    ]
    properties = Array(keypathProperties.values)
  }

  

  var keypathName: String

  let opacity: NodeProperty<Vector1D>
  let color: NodeProperty<Color>
  let type: FillRule

  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]

}



final class FillNode: AnimatorNode, RenderNode {

  

  init(parentNode: AnimatorNode?, fill: Fill) {
    fillRender = FillRenderer(parent: parentNode?.outputNode)
    fillProperties = FillNodeProperties(fill: fill)
    self.parentNode = parentNode
  }

  

  let fillRender: FillRenderer

  let fillProperties: FillNodeProperties

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
    fillRender.color = fillProperties.color.value.cgColorValue
    fillRender.opacity = fillProperties.opacity.value.cgFloatValue * 0.01
    fillRender.fillRule = fillProperties.type
  }
}
