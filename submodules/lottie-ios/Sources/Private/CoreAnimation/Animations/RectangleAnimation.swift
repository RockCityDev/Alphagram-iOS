


import QuartzCore

extension CAShapeLayer {
  
  @nonobjc
  func addAnimations(
    for rectangle: Rectangle,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: rectangle.size.keyframes,
      value: { sizeKeyframe in
        BezierPath.rectangle(
          position: try rectangle.position
            .exactlyOneKeyframe(context: context, description: "rectangle position").value.pointValue,
          size: sizeKeyframe.sizeValue,
          cornerRadius: try rectangle.cornerRadius
            .exactlyOneKeyframe(context: context, description: "rectangle cornerRadius").value.cgFloatValue,
          direction: rectangle.direction)
          .cgPath()
      },
      context: context)
  }
}
