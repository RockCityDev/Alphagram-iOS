






import Foundation
import QuartzCore



final class StrokeNodeProperties: NodePropertyMap, KeypathSearchable {

  

  init(stroke: Stroke) {
    keypathName = stroke.name
    color = NodeProperty(provider: KeyframeInterpolator(keyframes: stroke.color.keyframes))
    opacity = NodeProperty(provider: KeyframeInterpolator(keyframes: stroke.opacity.keyframes))
    width = NodeProperty(provider: KeyframeInterpolator(keyframes: stroke.width.keyframes))
    miterLimit = CGFloat(stroke.miterLimit)
    lineCap = stroke.lineCap
    lineJoin = stroke.lineJoin

    if let dashes = stroke.dashPattern {
      let (dashPatterns, dashPhase) = dashes.shapeLayerConfiguration
      dashPattern = NodeProperty(provider: GroupInterpolator(keyframeGroups: dashPatterns))
      if dashPhase.count == 0 {
        self.dashPhase = NodeProperty(provider: SingleValueProvider(Vector1D(0)))
      } else {
        self.dashPhase = NodeProperty(provider: KeyframeInterpolator(keyframes: dashPhase))
      }
    } else {
      dashPattern = NodeProperty(provider: SingleValueProvider([Vector1D]()))
      dashPhase = NodeProperty(provider: SingleValueProvider(Vector1D(0)))
    }
    keypathProperties = [
      "Opacity" : opacity,
      PropertyName.color.rawValue : color,
      "Stroke Width" : width,
      "Dashes" : dashPattern,
      "Dash Phase" : dashPhase,
    ]
    properties = Array(keypathProperties.values)
  }

  

  let keypathName: String
  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]

  let opacity: NodeProperty<Vector1D>
  let color: NodeProperty<Color>
  let width: NodeProperty<Vector1D>

  let dashPattern: NodeProperty<[Vector1D]>
  let dashPhase: NodeProperty<Vector1D>

  let lineCap: LineCap
  let lineJoin: LineJoin
  let miterLimit: CGFloat

}




final class StrokeNode: AnimatorNode, RenderNode {

  

  init(parentNode: AnimatorNode?, stroke: Stroke) {
    strokeRender = StrokeRenderer(parent: parentNode?.outputNode)
    strokeProperties = StrokeNodeProperties(stroke: stroke)
    self.parentNode = parentNode
  }

  

  let strokeRender: StrokeRenderer

  let strokeProperties: StrokeNodeProperties

  let parentNode: AnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

  var renderer: NodeOutput & Renderable {
    strokeRender
  }

  

  var propertyMap: NodePropertyMap & KeypathSearchable {
    strokeProperties
  }

  var isEnabled = true {
    didSet {
      strokeRender.isEnabled = isEnabled
    }
  }

  func localUpdatesPermeateDownstream() -> Bool {
    false
  }

  func rebuildOutputs(frame _: CGFloat) {
    strokeRender.color = strokeProperties.color.value.cgColorValue
    strokeRender.opacity = strokeProperties.opacity.value.cgFloatValue * 0.01
    strokeRender.width = strokeProperties.width.value.cgFloatValue
    strokeRender.miterLimit = strokeProperties.miterLimit
    strokeRender.lineCap = strokeProperties.lineCap
    strokeRender.lineJoin = strokeProperties.lineJoin

    
    let dashLengths = strokeProperties.dashPattern.value.map { $0.cgFloatValue }
    if dashLengths.count > 0 {
      strokeRender.dashPhase = strokeProperties.dashPhase.value.cgFloatValue
      strokeRender.dashLengths = dashLengths
    } else {
      strokeRender.dashLengths = nil
      strokeRender.dashPhase = nil
    }
  }

}



extension Array where Element == DashElement {
  typealias ShapeLayerConfiguration = (
    dashPatterns: ContiguousArray<ContiguousArray<Keyframe<Vector1D>>>,
    dashPhase: ContiguousArray<Keyframe<Vector1D>>)

  
  
  var shapeLayerConfiguration: ShapeLayerConfiguration {
    var dashPatterns = ContiguousArray<ContiguousArray<Keyframe<Vector1D>>>()
    var dashPhase = ContiguousArray<Keyframe<Vector1D>>()
    for dash in self {
      if dash.type == .offset {
        dashPhase = dash.value.keyframes
      } else {
        dashPatterns.append(dash.value.keyframes)
      }
    }
    return (dashPatterns, dashPhase)
  }
}
