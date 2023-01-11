


import QuartzCore






protocol TransformModel {
  
  var anchorPoint: KeyframeGroup<Vector3D> { get }

  
  var _position: KeyframeGroup<Vector3D>? { get }

  
  var _positionX: KeyframeGroup<Vector1D>? { get }

  
  var _positionY: KeyframeGroup<Vector1D>? { get }

  
  var scale: KeyframeGroup<Vector3D> { get }

  
  var rotation: KeyframeGroup<Vector1D> { get }
}



extension Transform: TransformModel {
  var _position: KeyframeGroup<Vector3D>? { position }
  var _positionX: KeyframeGroup<Vector1D>? { positionX }
  var _positionY: KeyframeGroup<Vector1D>? { positionY }
}



extension ShapeTransform: TransformModel {
  var anchorPoint: KeyframeGroup<Vector3D> { anchor }
  var _position: KeyframeGroup<Vector3D>? { position }
  var _positionX: KeyframeGroup<Vector1D>? { nil }
  var _positionY: KeyframeGroup<Vector1D>? { nil }
}



extension CALayer {

  

  
  
  
  @nonobjc
  func addTransformAnimations(for transformModel: TransformModel, context: LayerAnimationContext) throws {
    try addPositionAnimations(from: transformModel, context: context)
    try addAnchorPointAnimation(from: transformModel, context: context)
    try addScaleAnimations(from: transformModel, context: context)
    try addRotationAnimation(from: transformModel, context: context)
  }

  

  @nonobjc
  private func addPositionAnimations(
    from transformModel: TransformModel,
    context: LayerAnimationContext)
    throws
  {
    if let positionKeyframes = transformModel._position?.keyframes {
      try addAnimation(
        for: .position,
        keyframes: positionKeyframes,
        value: \.pointValue,
        context: context)
    } else if
      let xKeyframes = transformModel._positionX?.keyframes,
      let yKeyframes = transformModel._positionY?.keyframes
    {
      try addAnimation(
        for: .positionX,
        keyframes: xKeyframes,
        value: \.cgFloatValue,
        context: context)

      try addAnimation(
        for: .positionY,
        keyframes: yKeyframes,
        value: \.cgFloatValue,
        context: context)
    } else {
      try context.logCompatibilityIssue("""
        `Transform` values must provide either `position` or `positionX` / `positionY` keyframes
        """)
    }
  }

  @nonobjc
  private func addAnchorPointAnimation(
    from transformModel: TransformModel,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .anchorPoint,
      keyframes: transformModel.anchorPoint.keyframes,
      value: { absoluteAnchorPoint in
        guard bounds.width > 0, bounds.height > 0 else {
          LottieLogger.shared.assertionFailure("Size must be non-zero before an animation can be played")
          return .zero
        }

        
        
        
        return CGPoint(
          x: CGFloat(absoluteAnchorPoint.x) / bounds.width,
          y: CGFloat(absoluteAnchorPoint.y) / bounds.height)
      },
      context: context)
  }

  @nonobjc
  private func addScaleAnimations(
    from transformModel: TransformModel,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .scaleX,
      keyframes: transformModel.scale.keyframes,
      value: { scale in
        
        
        
        
        
        
        
        
        
        abs(CGFloat(scale.x) / 100)
      },
      context: context)

    
    
    
    
    if TestHelpers.snapshotTestsAreRunning {
      if transformModel.scale.keyframes.contains(where: { $0.value.x < 0 }) {
        LottieLogger.shared.warn("""
          Negative `scale.x` values are not displayed correctly in snapshot tests
          """)
      }
    } else {
      try addAnimation(
        for: .rotationY,
        keyframes: transformModel.scale.keyframes,
        value: { scale in
          if scale.x < 0 {
            return .pi
          } else {
            return 0
          }
        },
        context: context)
    }

    try addAnimation(
      for: .scaleY,
      keyframes: transformModel.scale.keyframes,
      value: { scale in
        
        
        
        
        
        
        CGFloat(scale.y) / 100
      },
      context: context)
  }

  private func addRotationAnimation(
    from transformModel: TransformModel,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .rotation,
      keyframes: transformModel.rotation.keyframes,
      value: { rotationDegrees in
        
        
        
        rotationDegrees.cgFloatValue * .pi / 180
      },
      context: context)
  }

}
