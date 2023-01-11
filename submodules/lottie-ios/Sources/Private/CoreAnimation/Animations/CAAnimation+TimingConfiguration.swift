


import QuartzCore

extension CAAnimation {
  
  
  @nonobjc
  func timed(with context: LayerAnimationContext, for layer: CALayer) -> CAAnimation {

    
    
    
    
    
    
    
    
    
    let baseAnimation = self
    baseAnimation.duration = context.animation.duration
    baseAnimation.speed = (context.endFrame < context.startFrame) ? -1 : 1

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    let clippingParent = CAAnimationGroup()
    clippingParent.animations = [baseAnimation]

    clippingParent.duration = Double(abs(context.endFrame - context.startFrame)) / context.animation.framerate
    baseAnimation.timeOffset = context.animation.time(forFrame: context.startFrame)

    clippingParent.autoreverses = context.timingConfiguration.autoreverses
    clippingParent.repeatCount = context.timingConfiguration.repeatCount
    clippingParent.timeOffset = context.timingConfiguration.timeOffset

    
    clippingParent.fillMode = .both
    clippingParent.isRemovedOnCompletion = false

    
    
    
    
    
    
    
    
    if context.timingConfiguration.speed == 0 {
      let currentTime = layer.convertTime(CACurrentMediaTime(), from: nil)
      clippingParent.beginTime = currentTime - .leastNonzeroMagnitude
    }

    return clippingParent
  }
}

extension CALayer {
  
  @nonobjc
  func add(_ animation: CAPropertyAnimation, timedWith context: LayerAnimationContext) {
    add(animation.timed(with: context, for: self), forKey: animation.keyPath)
  }
}
