






import CoreGraphics
import Foundation



final class RectNodeProperties: NodePropertyMap, KeypathSearchable {

  

  init(rectangle: Rectangle) {
    keypathName = rectangle.name
    direction = rectangle.direction
    position = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.position.keyframes))
    size = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.size.keyframes))
    cornerRadius = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.cornerRadius.keyframes))

    keypathProperties = [
      "Position" : position,
      "Size" : size,
      "Roundness" : cornerRadius,
    ]

    properties = Array(keypathProperties.values)
  }

  

  var keypathName: String

  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]

  let direction: PathDirection
  let position: NodeProperty<Vector3D>
  let size: NodeProperty<Vector3D>
  let cornerRadius: NodeProperty<Vector1D>

}



final class RectangleNode: AnimatorNode, PathNode {

  

  init(parentNode: AnimatorNode?, rectangle: Rectangle) {
    properties = RectNodeProperties(rectangle: rectangle)
    pathOutput = PathOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
  }

  

  let properties: RectNodeProperties

  let pathOutput: PathOutputNode
  let parentNode: AnimatorNode?
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil

  

  var propertyMap: NodePropertyMap & KeypathSearchable {
    properties
  }

  var isEnabled = true {
    didSet {
      pathOutput.isEnabled = isEnabled
    }
  }

  func rebuildOutputs(frame: CGFloat) {
    pathOutput.setPath(
      .rectangle(
        position: properties.position.value.pointValue,
        size: properties.size.value.sizeValue,
        cornerRadius: properties.cornerRadius.value.cgFloatValue,
        direction: properties.direction),
      updateFrame: frame)
  }

}



extension BezierPath {
  
  static func rectangle(
    position: CGPoint,
    size inputSize: CGSize,
    cornerRadius: CGFloat,
    direction: PathDirection)
    -> BezierPath
  {
    let size = inputSize * 0.5
    let radius = min(min(cornerRadius, size.width) , size.height)

    var bezierPath = BezierPath()
    let points: [CurveVertex]

    if radius <= 0 {
      
      points = [
        
        CurveVertex(
          point: CGPoint(x: size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(
          point: CGPoint(x: size.width, y: size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(
          point: CGPoint(x: -size.width, y: size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(
          point: CGPoint(x: -size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(
          point: CGPoint(x: size.width, y: -size.height),
          inTangentRelative: .zero,
          outTangentRelative: .zero)
          .translated(position),
      ]
    } else {
      let controlPoint = radius * EllipseNode.ControlPointConstant
      points = [
        
        CurveVertex(
          CGPoint(x: radius, y: 0),
          CGPoint(x: radius, y: 0),
          CGPoint(x: radius, y: 0))
          .translated(CGPoint(x: -radius, y: radius))
          .translated(CGPoint(x: size.width, y: -size.height))
          .translated(position),
        
        CurveVertex(
          CGPoint(x: radius, y: 0), 
          CGPoint(x: radius, y: 0), 
          CGPoint(x: radius, y: controlPoint))
          .translated(CGPoint(x: -radius, y: -radius))
          .translated(CGPoint(x: size.width, y: size.height))
          .translated(position),
        CurveVertex(
          CGPoint(x: controlPoint, y: radius), 
          CGPoint(x: 0, y: radius), 
          CGPoint(x: 0, y: radius)) 
          .translated(CGPoint(x: -radius, y: -radius))
          .translated(CGPoint(x: size.width, y: size.height))
          .translated(position),
        
        CurveVertex(
          CGPoint(x: 0, y: radius), 
          CGPoint(x: 0, y: radius), 
          CGPoint(x: -controlPoint, y: radius))
          .translated(CGPoint(x: radius, y: -radius))
          .translated(CGPoint(x: -size.width, y: size.height))
          .translated(position),
        CurveVertex(
          CGPoint(x: -radius, y: controlPoint), 
          CGPoint(x: -radius, y: 0), 
          CGPoint(x: -radius, y: 0)) 
          .translated(CGPoint(x: radius, y: -radius))
          .translated(CGPoint(x: -size.width, y: size.height))
          .translated(position),
        
        CurveVertex(
          CGPoint(x: -radius, y: 0), 
          CGPoint(x: -radius, y: 0), 
          CGPoint(x: -radius, y: -controlPoint)) 
          .translated(CGPoint(x: radius, y: radius))
          .translated(CGPoint(x: -size.width, y: -size.height))
          .translated(position),
        CurveVertex(
          CGPoint(x: -controlPoint, y: -radius), 
          CGPoint(x: 0, y: -radius), 
          CGPoint(x: 0, y: -radius)) 
          .translated(CGPoint(x: radius, y: radius))
          .translated(CGPoint(x: -size.width, y: -size.height))
          .translated(position),
        
        CurveVertex(
          CGPoint(x: 0, y: -radius), 
          CGPoint(x: 0, y: -radius), 
          CGPoint(x: controlPoint, y: -radius)) 
          .translated(CGPoint(x: -radius, y: radius))
          .translated(CGPoint(x: size.width, y: -size.height))
          .translated(position),
        CurveVertex(
          CGPoint(x: radius, y: -controlPoint), 
          CGPoint(x: radius, y: 0), 
          CGPoint(x: radius, y: 0)) 
          .translated(CGPoint(x: -radius, y: radius))
          .translated(CGPoint(x: size.width, y: -size.height))
          .translated(position),
      ]
    }
    let reversed = direction == .counterClockwise
    let pathPoints = reversed ? points.reversed() : points
    for point in pathPoints {
      bezierPath.addVertex(reversed ? point.reversed() : point)
    }
    bezierPath.close()
    return bezierPath
  }
}
