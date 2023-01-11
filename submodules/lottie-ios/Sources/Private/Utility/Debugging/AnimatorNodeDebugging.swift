






import Foundation

extension AnimatorNode {

  func printNodeTree() {
    parentNode?.printNodeTree()
    print(String(describing: type(of: self)))

    if let group = self as? GroupNode {
      print("* |Children")
      group.rootNode?.printNodeTree()
      print("*")
    } else {
      print("|")
    }
  }

}
