






import Foundation
import CoreGraphics

class PassThroughOutputNode: NodeOutput {
  
  init(parent: NodeOutput?) {
    self.parent = parent
  }
  
  let parent: NodeOutput?
  
  var hasUpdate: Bool = false
  var isEnabled: Bool = true
  
  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool {
    
    let parentUpdate = parent?.hasOutputUpdates(forFrame) ?? false
    
    hasUpdate = hasUpdate || parentUpdate
    return parentUpdate
  }
  
  var outputPath: CGPath? {
    if let parent = parent {
      return parent.outputPath
    }
    return nil
  }
  
  func hasRenderUpdates(_ forFrame: CGFloat) -> Bool {
    
    let upstreamUpdates = parent?.hasOutputUpdates(forFrame) ?? false
    hasUpdate = hasUpdate || upstreamUpdates
    return hasUpdate
  }
}
