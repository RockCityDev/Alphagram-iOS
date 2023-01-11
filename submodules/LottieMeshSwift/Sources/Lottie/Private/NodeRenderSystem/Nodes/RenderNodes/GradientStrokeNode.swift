






import Foundation
import CoreGraphics



final class GradientStrokeProperties: NodePropertyMap {
  
  init(gradientStroke: GradientStroke) {
    self.opacity = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientStroke.opacity.keyframes))
    self.startPoint = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientStroke.startPoint.keyframes))
    self.endPoint = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientStroke.endPoint.keyframes))
    self.colors = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientStroke.colors.keyframes))
    self.gradientType = gradientStroke.gradientType
    self.numberOfColors = gradientStroke.numberOfColors
    self.width = NodeProperty(provider: KeyframeInterpolator(keyframes: gradientStroke.width.keyframes))
    self.miterLimit = CGFloat(gradientStroke.miterLimit)
    self.lineCap = gradientStroke.lineCap
    self.lineJoin = gradientStroke.lineJoin
    
    if let dashes = gradientStroke.dashPattern {
      var dashPatterns = ContiguousArray<ContiguousArray<Keyframe<Vector1D>>>()
      var dashPhase = ContiguousArray<Keyframe<Vector1D>>()
      for dash in dashes {
        if dash.type == .offset {
          dashPhase = dash.value.keyframes
        } else {
          dashPatterns.append(dash.value.keyframes)
        }
      }
      self.dashPattern = NodeProperty(provider: GroupInterpolator(keyframeGroups: dashPatterns))
      self.dashPhase = NodeProperty(provider: KeyframeInterpolator(keyframes: dashPhase))
    } else {
      self.dashPattern = NodeProperty(provider: SingleValueProvider([Vector1D]()))
      self.dashPhase = NodeProperty(provider: SingleValueProvider(Vector1D(0)))
    }
    let keypathProperties: [String : AnyNodeProperty] = [
      "Opacity" : opacity,
      "Start Point" : startPoint,
      "End Point" : endPoint,
      "Colors" : colors,
      "Stroke Width" : width,
      "Dashes" : dashPattern,
      "Dash Phase" : dashPhase
    ]
    self.properties = Array(keypathProperties.values)
  }
  
  let opacity: NodeProperty<Vector1D>
  let startPoint: NodeProperty<Vector3D>
  let endPoint: NodeProperty<Vector3D>
  let colors: NodeProperty<[Double]>
  let width: NodeProperty<Vector1D>
  
  let dashPattern: NodeProperty<[Vector1D]>
  let dashPhase: NodeProperty<Vector1D>
  
  let lineCap: LineCap
  let lineJoin: LineJoin
  let miterLimit: CGFloat
  let gradientType: GradientType
  let numberOfColors: Int
  
  
  let properties: [AnyNodeProperty]
  
}



final class GradientStrokeNode: AnimatorNode, RenderNode {
  
  let strokeRender: GradientStrokeRenderer
  
  var renderer: NodeOutput & Renderable {
    return strokeRender
  }
  
  let strokeProperties: GradientStrokeProperties
  
  init(parentNode: AnimatorNode?, gradientStroke: GradientStroke) {
    self.strokeRender = GradientStrokeRenderer(parent: parentNode?.outputNode)
    self.strokeProperties = GradientStrokeProperties(gradientStroke: gradientStroke)
    self.parentNode = parentNode
  }
  
  
  
  var propertyMap: NodePropertyMap {
    return strokeProperties
  }
  
  let parentNode: AnimatorNode?
  var hasLocalUpdates: Bool = false
  var hasUpstreamUpdates: Bool = false
  var lastUpdateFrame: CGFloat? = nil
  var isEnabled: Bool = true {
    didSet {
      strokeRender.isEnabled = isEnabled
    }
  }
  
  func localUpdatesPermeateDownstream() -> Bool {
    return false
  }
  
  func rebuildOutputs(frame: CGFloat) {
    
    strokeRender.gradientRender.start = strokeProperties.startPoint.value.pointValue
    strokeRender.gradientRender.end = strokeProperties.endPoint.value.pointValue
    strokeRender.gradientRender.opacity = strokeProperties.opacity.value.cgFloatValue
    strokeRender.gradientRender.colors = strokeProperties.colors.value.map { CGFloat($0) }
    strokeRender.gradientRender.type = strokeProperties.gradientType
    strokeRender.gradientRender.numberOfColors = strokeProperties.numberOfColors
    
    
    strokeRender.strokeRender.opacity = strokeProperties.opacity.value.cgFloatValue
    strokeRender.strokeRender.width = strokeProperties.width.value.cgFloatValue
    strokeRender.strokeRender.miterLimit = strokeProperties.miterLimit
    strokeRender.strokeRender.lineCap = strokeProperties.lineCap
    strokeRender.strokeRender.lineJoin = strokeProperties.lineJoin
    
    
    let dashLengths = strokeProperties.dashPattern.value.map { $0.cgFloatValue }
    if dashLengths.count > 0 {
      strokeRender.strokeRender.dashPhase = strokeProperties.dashPhase.value.cgFloatValue
      strokeRender.strokeRender.dashLengths = dashLengths
    } else {
      strokeRender.strokeRender.dashLengths = nil
      strokeRender.strokeRender.dashPhase = nil
    }
  }
}
