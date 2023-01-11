


import QuartzCore





protocol AnimationLayer: CALayer {
  
  
  func setupAnimations(context: LayerAnimationContext) throws
}




struct LayerAnimationContext {
  
  let animation: Animation

  
  let timingConfiguration: CoreAnimationLayer.CAMediaTimingConfiguration

  
  let startFrame: AnimationFrameTime

  
  let endFrame: AnimationFrameTime

  
  let valueProviderStore: ValueProviderStore

  
  let compatibilityTracker: CompatibilityTracker

  
  var currentKeypath: AnimationKeypath

  
  
  private(set) var timeRemapping: ((AnimationFrameTime) -> AnimationFrameTime) = { $0 }

  
  
  func addingKeypathComponent(_ component: String) -> LayerAnimationContext {
    var context = self
    context.currentKeypath.keys.append(component)
    return context
  }

  
  
  func progressTime(for frame: AnimationFrameTime) -> AnimationProgressTime {
    animation.progressTime(forFrame: timeRemapping(frame), clamped: false)
  }

  
  func withTimeRemapping(
    _ additionalTimeRemapping: @escaping (AnimationFrameTime) -> AnimationFrameTime)
    -> LayerAnimationContext
  {
    var copy = self
    copy.timeRemapping = { [existingTimeRemapping = timeRemapping] time in
      existingTimeRemapping(additionalTimeRemapping(time))
    }
    return copy
  }
}
