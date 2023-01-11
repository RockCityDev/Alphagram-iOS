






import CoreGraphics
import Foundation


class PathOutputNode: NodeOutput {

  

  init(parent: NodeOutput?) {
    self.parent = parent
  }

  

  let parent: NodeOutput?

  fileprivate(set) var outputPath: CGPath? = nil

  var lastUpdateFrame: CGFloat? = nil
  var lastPathBuildFrame: CGFloat? = nil
  var isEnabled = true
  fileprivate(set) var totalLength: CGFloat = 0
  fileprivate(set) var pathObjects: [CompoundBezierPath] = []

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    guard isEnabled else {
      let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
      outputPath = parent?.outputPath
      return upstreamUpdates
    }

    
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false

    
    if upstreamUpdates && lastPathBuildFrame != forFrame {
      outputPath = nil
    }

    if outputPath == nil {
      
      lastPathBuildFrame = forFrame
      let newPath = CGMutablePath()
      if let parentNode = parent, let parentPath = parentNode.outputPath {
        newPath.addPath(parentPath)
      }
      for path in pathObjects {
        for subPath in path.paths {
          newPath.addPath(subPath.cgPath())
        }
      }
      outputPath = newPath
    }

    
    return upstreamUpdates || (lastUpdateFrame == forFrame)
  }

  @discardableResult
  func removePaths(updateFrame: CGFloat?) -> [CompoundBezierPath] {
    lastUpdateFrame = updateFrame
    let returnPaths = pathObjects
    outputPath = nil
    totalLength = 0
    pathObjects = []
    return returnPaths
  }

  func setPath(_ path: BezierPath, updateFrame: CGFloat) {
    lastUpdateFrame = updateFrame
    outputPath = nil
    totalLength = path.length
    pathObjects = [CompoundBezierPath(path: path)]
  }

  func appendPath(_ path: CompoundBezierPath, updateFrame: CGFloat) {
    lastUpdateFrame = updateFrame
    outputPath = nil
    totalLength = totalLength + path.length
    pathObjects.append(path)
  }

}
