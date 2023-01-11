


import QuartzCore

extension CALayer {
  
  @nonobjc
  func addVisibilityAnimation(
    inFrame: AnimationFrameTime,
    outFrame: AnimationFrameTime,
    context: LayerAnimationContext)
  {
    let animation = CAKeyframeAnimation(keyPath: #keyPath(isHidden))
    animation.calculationMode = .discrete

    animation.values = [
      true, 
      false, 
      true, 
    ]

    
    
    
    
    
    animation.keyTimes = [
      NSNumber(value: 0.0),
      NSNumber(value: max(Double(context.progressTime(for: inFrame)), 0)),
      NSNumber(value: min(Double(context.progressTime(for: outFrame)), 1)),
      NSNumber(value: 1.0),
    ]

    add(animation, timedWith: context)
  }
}
