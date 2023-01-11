


import QuartzCore

extension CAShapeLayer {
  
  @nonobjc
  func addAnimations(
    for combinedShapes: CombinedShapeItem,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: combinedShapes.shapes.keyframes,
      value: { paths in
        let combinedPath = CGMutablePath()
        for path in paths {
          combinedPath.addPath(path.cgPath())
        }
        return combinedPath
      },
      context: context)
  }
}




final class CombinedShapeItem: ShapeItem {

  

  init(shapes: KeyframeGroup<[BezierPath]>, name: String) {
    self.shapes = shapes
    super.init(name: name, type: .shape, hidden: false)
  }

  required init(from _: Decoder) throws {
    fatalError("init(from:) has not been implemented")
  }

  required init(dictionary _: [String: Any]) throws {
    fatalError("init(dictionary:) has not been implemented")
  }

  

  let shapes: KeyframeGroup<[BezierPath]>

}
