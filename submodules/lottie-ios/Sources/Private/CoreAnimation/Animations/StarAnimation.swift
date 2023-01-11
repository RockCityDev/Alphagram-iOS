


import QuartzCore

extension CAShapeLayer {

  

  
  @nonobjc
  func addAnimations(
    for star: Star,
    context: LayerAnimationContext)
    throws
  {
    switch star.starType {
    case .star:
      try addStarAnimation(for: star, context: context)
    case .polygon:
      try addPolygonAnimation(for: star, context: context)
    case .none:
      break
    }
  }

  

  @nonobjc
  private func addStarAnimation(
    for star: Star,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: star.position.keyframes,
      value: { position in
        
        
        
        BezierPath.star(
          position: position.pointValue,
          outerRadius: try star.outerRadius
            .exactlyOneKeyframe(context: context, description: "outerRadius").value.cgFloatValue,
          innerRadius: try star.innerRadius?
            .exactlyOneKeyframe(context: context, description: "innerRadius").value.cgFloatValue ?? 0,
          outerRoundedness: try star.outerRoundness
            .exactlyOneKeyframe(context: context, description: "outerRoundness").value.cgFloatValue,
          innerRoundedness: try star.innerRoundness?
            .exactlyOneKeyframe(context: context, description: "innerRoundness").value.cgFloatValue ?? 0,
          numberOfPoints: try star.points
            .exactlyOneKeyframe(context: context, description: "points").value.cgFloatValue,
          rotation: try star.rotation
            .exactlyOneKeyframe(context: context, description: "rotation").value.cgFloatValue,
          direction: star.direction)
          .cgPath()
      },
      context: context)
  }

  @nonobjc
  private func addPolygonAnimation(
    for star: Star,
    context: LayerAnimationContext)
    throws
  {
    try addAnimation(
      for: .path,
      keyframes: star.position.keyframes,
      value: { position in
        
        
        
        BezierPath.polygon(
          position: position.pointValue,
          numberOfPoints: try star.points
            .exactlyOneKeyframe(context: context, description: "numberOfPoints").value.cgFloatValue,
          outerRadius: try star.outerRadius
            .exactlyOneKeyframe(context: context, description: "outerRadius").value.cgFloatValue,
          outerRoundedness: try star.outerRoundness
            .exactlyOneKeyframe(context: context, description: "outerRoundedness").value.cgFloatValue,
          rotation: try star.rotation
            .exactlyOneKeyframe(context: context, description: "rotation").value.cgFloatValue,
          direction: star.direction)
          .cgPath()
      },
      context: context)
  }
}
