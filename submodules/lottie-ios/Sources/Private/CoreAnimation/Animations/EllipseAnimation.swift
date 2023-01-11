


import QuartzCore

extension CAShapeLayer {
  
  @nonobjc
  func addAnimations(
    for ellipse: Ellipse,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: ellipse.size.keyframes,
      value: { sizeKeyframe in
        BezierPath.ellipse(
          size: sizeKeyframe.sizeValue,
          center: try ellipse.position.exactlyOneKeyframe(context: context, description: "ellipse position").value.pointValue,
          direction: ellipse.direction)
          .cgPath()
      },
      context: context)
  }
}
