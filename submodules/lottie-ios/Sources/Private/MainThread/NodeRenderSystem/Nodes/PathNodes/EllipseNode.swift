






import Foundation
import QuartzCore



final class EllipseNodeProperties: NodePropertyMap, KeypathSearchable {

  

  init(ellipse: Ellipse) {
    keypathName = ellipse.name
    direction = ellipse.direction
    position = NodeProperty(provider: KeyframeInterpolator(keyframes: ellipse.position.keyframes))
    size = NodeProperty(provider: KeyframeInterpolator(keyframes: ellipse.size.keyframes))
    keypathProperties = [
      "Position" : position,
      "Size" : size,
    ]
    properties = Array(keypathProperties.values)
  }

  

  var keypathName: String

  let direction: PathDirection
  let position: NodeProperty<Vector3D>
  let size: NodeProperty<Vector3D>

  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]
}



final class EllipseNode: AnimatorNode, PathNode {

  

  init(parentNode: AnimatorNode?, ellipse: Ellipse) {
    pathOutput = PathOutputNode(parent: parentNode?.outputNode)
    properties = EllipseNodeProperties(ellipse: ellipse)
    self.parentNode = parentNode
  }

  

  static let ControlPointConstant: CGFloat = 0.55228

  let pathOutput: PathOutputNode

  let properties: EllipseNodeProperties

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
      .ellipse(
        size: properties.size.value.sizeValue,
        center: properties.position.value.pointValue,
        direction: properties.direction),
      updateFrame: frame)
  }

}

extension BezierPath {
  
  static func ellipse(
    size: CGSize,
    center: CGPoint,
    direction: PathDirection)
    -> BezierPath
  {
    
    
    
    
    var half = size * 0.5
    if direction == .counterClockwise {
      half.width = half.width * -1
    }

    let q1 = CGPoint(x: center.x, y: center.y - half.height)
    let q2 = CGPoint(x: center.x + half.width, y: center.y)
    let q3 = CGPoint(x: center.x, y: center.y + half.height)
    let q4 = CGPoint(x: center.x - half.width, y: center.y)

    let cp = half * EllipseNode.ControlPointConstant

    var path = BezierPath(startPoint: CurveVertex(
      point: q1,
      inTangentRelative: CGPoint(x: -cp.width, y: 0),
      outTangentRelative: CGPoint(x: cp.width, y: 0)))
    path.addVertex(CurveVertex(
      point: q2,
      inTangentRelative: CGPoint(x: 0, y: -cp.height),
      outTangentRelative: CGPoint(x: 0, y: cp.height)))

    path.addVertex(CurveVertex(
      point: q3,
      inTangentRelative: CGPoint(x: cp.width, y: 0),
      outTangentRelative: CGPoint(x: -cp.width, y: 0)))

    path.addVertex(CurveVertex(
      point: q4,
      inTangentRelative: CGPoint(x: 0, y: cp.height),
      outTangentRelative: CGPoint(x: 0, y: -cp.height)))

    path.addVertex(CurveVertex(
      point: q1,
      inTangentRelative: CGPoint(x: -cp.width, y: 0),
      outTangentRelative: CGPoint(x: cp.width, y: 0)))
    path.close()
    return path
  }
}
