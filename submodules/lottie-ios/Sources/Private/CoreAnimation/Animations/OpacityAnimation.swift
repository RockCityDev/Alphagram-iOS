


import QuartzCore



protocol OpacityAnimationModel {
  
  var opacity: KeyframeGroup<Vector1D> { get }
}



extension Transform: OpacityAnimationModel { }



extension ShapeTransform: OpacityAnimationModel { }



extension Fill: OpacityAnimationModel { }



extension GradientFill: OpacityAnimationModel { }



extension Stroke: OpacityAnimationModel { }



extension GradientStroke: OpacityAnimationModel { }

extension CALayer {
  
  @nonobjc
  func addOpacityAnimation(for opacity: OpacityAnimationModel, context: LayerAnimationContext) throws {
    try addAnimation(
      for: .opacity,
      keyframes: opacity.opacity.keyframes,
      value: {
        
        
        
        $0.cgFloatValue / 100
      },
      context: context)
  }
}
