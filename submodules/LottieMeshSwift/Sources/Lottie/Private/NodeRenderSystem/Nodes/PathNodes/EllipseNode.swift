






import Foundation
import QuartzCore

final class EllipseNodeProperties: NodePropertyMap {
  
  init(ellipse: Ellipse) {
    self.direction = ellipse.direction
    self.position = NodeProperty(provider: KeyframeInterpolator(keyframes: ellipse.position.keyframes))
    self.size = NodeProperty(provider: KeyframeInterpolator(keyframes: ellipse.size.keyframes))
    self.properties = []
  }
  
  let direction: PathDirection
  let position: NodeProperty<Vector3D>
  let size: NodeProperty<Vector3D>
  
  let properties: [AnyNodeProperty]
}

final class EllipseNode: AnimatorNode, PathNode {
  
  let pathOutput: PathOutputNode
  
  let properties: EllipseNodeProperties

  init(parentNode: AnimatorNode?, ellipse: Ellipse) {
    self.pathOutput = PathOutputNode(parent: parentNode?.outputNode)
    self.properties = EllipseNodeProperties(ellipse: ellipse)
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
    let ellipseSize = properties.size.value.sizeValue
    let center = properties.position.value.pointValue
    
    
    
    
    
    
    var half = ellipseSize * 0.5
    if properties.direction == .counterClockwise {
      half.width = half.width * -1
    }
    
    
    let q1 = CGPoint(x: center.x, y: center.y - half.height)
    let q2 = CGPoint(x: center.x + half.width, y: center.y)
    let q3 = CGPoint(x: center.x, y: center.y + half.height)
    let q4 = CGPoint(x: center.x - half.width, y: center.y)
    
    let cp = half * EllipseNode.ControlPointConstant
    
    var path = BezierPath(startPoint: CurveVertex(point: q1,
                                                  inTangentRelative: CGPoint(x: -cp.width, y: 0),
                                                  outTangentRelative: CGPoint(x: cp.width, y: 0)))
    path.addVertex(CurveVertex(point: q2,
                               inTangentRelative: CGPoint(x: 0, y: -cp.height),
                               outTangentRelative: CGPoint(x: 0, y: cp.height)))
    
    path.addVertex(CurveVertex(point: q3,
                               inTangentRelative: CGPoint(x: cp.width, y: 0),
                               outTangentRelative: CGPoint(x: -cp.width, y: 0)))
    
    path.addVertex(CurveVertex(point: q4,
                               inTangentRelative: CGPoint(x: 0, y: cp.height),
                               outTangentRelative: CGPoint(x: 0, y: -cp.height)))
    
    path.addVertex(CurveVertex(point: q1,
                               inTangentRelative: CGPoint(x: -cp.width, y: 0),
                               outTangentRelative: CGPoint(x: cp.width, y: 0)))
    path.close()
    pathOutput.setPath(path, updateFrame: frame)
  }

  static let ControlPointConstant: CGFloat = 0.55228
  
}
