


import QuartzCore

extension CAShapeLayer {
  
  @nonobjc
  func addAnimations(
    for customPath: KeyframeGroup<BezierPath>,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: customPath.keyframes,
      value: { pathKeyframe in
        pathKeyframe.cgPath()
      },
      context: context)
  }
}
