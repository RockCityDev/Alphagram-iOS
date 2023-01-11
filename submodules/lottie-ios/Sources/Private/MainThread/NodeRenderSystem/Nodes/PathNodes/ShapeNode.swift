






import CoreGraphics
import Foundation



final class ShapeNodeProperties: NodePropertyMap, KeypathSearchable {

  

  init(shape: Shape) {
    keypathName = shape.name
    path = NodeProperty(provider: KeyframeInterpolator(keyframes: shape.path.keyframes))
    keypathProperties = [
      "Path" : path,
    ]
    properties = Array(keypathProperties.values)
  }

  

  var keypathName: String

  let path: NodeProperty<BezierPath>
  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]

}



final class ShapeNode: AnimatorNode, PathNode {

  

  init(parentNode: AnimatorNode?, shape: Shape) {
    pathOutput = PathOutputNode(parent: parentNode?.outputNode)
    properties = ShapeNodeProperties(shape: shape)
    self.parentNode = parentNode
  }

  

  let properties: ShapeNodeProperties

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
    pathOutput.setPath(properties.path.value, updateFrame: frame)
  }

}
