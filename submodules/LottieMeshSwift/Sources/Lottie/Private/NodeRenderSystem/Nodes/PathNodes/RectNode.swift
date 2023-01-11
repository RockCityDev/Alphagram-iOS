






import Foundation
import CoreGraphics

final class RectNodeProperties: NodePropertyMap {

  init(rectangle: Rectangle) {
    self.direction = rectangle.direction
    self.position = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.position.keyframes))
    self.size = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.size.keyframes))
    self.cornerRadius = NodeProperty(provider: KeyframeInterpolator(keyframes: rectangle.cornerRadius.keyframes))
 
    let keypathProperties: [String : AnyNodeProperty] = [
      "Position" : position,
      "Size" : size,
      "Roundness" : cornerRadius
    ]
    
    self.properties = Array(keypathProperties.values)
  }
  
  let properties: [AnyNodeProperty]
  
  let direction: PathDirection
  let position: NodeProperty<Vector3D>
  let size: NodeProperty<Vector3D>
  let cornerRadius: NodeProperty<Vector1D>
  
}

final class RectangleNode: AnimatorNode, PathNode {
  
  let properties: RectNodeProperties
  
  let pathOutput: PathOutputNode
  
  init(parentNode: AnimatorNode?, rectangle: Rectangle) {
    self.properties = RectNodeProperties(rectangle: rectangle)
    self.pathOutput = PathOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
  }

  
  
  var propertyMap: NodePropertyMap {
    return properties
  }

  let parentNode: AnimatorNode?
  var hasLocalUpdates: Bool = false
  var hasUpstreamUpdates: Bool = false
  var lastUpdateFrame: CGFloat? = nil
  var isEnabled: Bool = true {
    didSet{
      self.pathOutput.isEnabled = self.isEnabled
    }
  }
  
  func rebuildOutputs(frame: CGFloat) {
    
    let size = properties.size.value.sizeValue * 0.5
    let radius = min(min(properties.cornerRadius.value.cgFloatValue, size.width) , size.height)
    let position = properties.position.value.pointValue
    var bezierPath = BezierPath()
    let points: [CurveVertex]
    
    if radius <= 0 {
      
      points = [
        
        CurveVertex(point: CGPoint(x: size.width, y: -size.height),
                    inTangentRelative: .zero,
                    outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(point: CGPoint(x: size.width, y: size.height),
                    inTangentRelative: .zero,
                    outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(point: CGPoint(x: -size.width, y: size.height),
                    inTangentRelative: .zero,
                    outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(point: CGPoint(x: -size.width, y: -size.height),
                    inTangentRelative: .zero,
                    outTangentRelative: .zero)
          .translated(position),
        
        CurveVertex(point: CGPoint(x: size.width, y: -size.height),
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
    let reversed = properties.direction == .counterClockwise
    let pathPoints = reversed ? points.reversed() : points
    for point in pathPoints {
      bezierPath.addVertex(reversed ? point.reversed() : point)
    }
    bezierPath.close()
    pathOutput.setPath(bezierPath, updateFrame: frame)
  }
  
}
