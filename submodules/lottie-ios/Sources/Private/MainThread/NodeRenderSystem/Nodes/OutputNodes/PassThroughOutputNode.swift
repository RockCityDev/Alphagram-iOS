






import CoreGraphics
import Foundation

class PassThroughOutputNode: NodeOutput {

  

  init(parent: NodeOutput?) {
    self.parent = parent
  }

  

  let parent: NodeOutput?

  var hasUpdate = false
  var isEnabled = true

  var outputPath: CGPath? {
    if let parent = parent {
      return parent.outputPath
    }
    return nil
  }

  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    
    let parentUpdate = parent?.hasOutputUpdates(forFrame) ?? false
    
    hasUpdate = hasUpdate || parentUpdate
    return parentUpdate
  }

  func hasRenderUpdates(_ forFrame: CGFloat) -> Bool {
    
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
    hasUpdate = hasUpdate || upstreamUpdates
    return hasUpdate
  }
}
