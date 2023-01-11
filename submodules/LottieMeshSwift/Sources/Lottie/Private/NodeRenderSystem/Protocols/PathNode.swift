






import Foundation

protocol PathNode {
  var pathOutput: PathOutputNode { get }
}

extension PathNode where Self: AnimatorNode {
  
  var outputNode: NodeOutput {
    return pathOutput
  }
  
}
