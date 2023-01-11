






import CoreGraphics
import Foundation
import QuartzCore

class GroupOutputNode: NodeOutput {

  

  init(parent: NodeOutput?, rootNode: NodeOutput?) {
    self.parent = parent
    self.rootNode = rootNode
  }

  

  let parent: NodeOutput?
  let rootNode: NodeOutput?
  var isEnabled = true

  private(set) var outputPath: CGPath? = nil
  private(set) var transform: CATransform3D = CATransform3DIdentity

  func setTransform(_ xform: CATransform3D, forFrame _: CGFloat) {
    transform = xform
    outputPath = nil
  }

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    guard isEnabled else {
      let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
      outputPath = parent?.outputPath
      return upstreamUpdates
    }

    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
    if upstreamUpdates {
      outputPath = nil
    }
    let rootUpdates = rootNode?.hasOutputUpdates(forFrame) ?? false
    if rootUpdates {
      outputPath = nil
    }

    var localUpdates = false
    if outputPath == nil {
      localUpdates = true

      let newPath = CGMutablePath()
      if let parentNode = parent, let parentPath = parentNode.outputPath {
        
        newPath.addPath(parentPath)
      }
      var xform = CATransform3DGetAffineTransform(transform)
      if
        let rootNode = rootNode,
        let rootPath = rootNode.outputPath,
        let xformedPath = rootPath.copy(using: &xform)
      {
        
        newPath.addPath(xformedPath)
      }

      outputPath = newPath
    }

    return upstreamUpdates || localUpdates
  }

}
