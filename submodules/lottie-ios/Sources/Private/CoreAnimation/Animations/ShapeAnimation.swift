


import QuartzCore

extension CAShapeLayer {
  
  @nonobjc
  func addAnimations(for shape: ShapeItem, context: LayerAnimationContext) throws {
    switch shape {
    case let customShape as Shape:
      try addAnimations(for: customShape.path, context: context)

    case let combinedShape as CombinedShapeItem:
      try addAnimations(for: combinedShape, context: context)

    case let ellipse as Ellipse:
      try addAnimations(for: ellipse, context: context)

    case let rectangle as Rectangle:
      try addAnimations(for: rectangle, context: context)

    case let star as Star:
      try addAnimations(for: star, context: context)

    default:
      
      try context.logCompatibilityIssue("Unexpected shape type \(type(of: shape))")
      return
    }
  }

  
  @nonobjc
  func addAnimations(for fill: Fill, context: LayerAnimationContext) throws {
    fillRule = fill.fillRule.caFillRule

    try addAnimation(
      for: .fillColor,
      keyframes: fill.color.keyframes,
      value: \.cgColorValue,
      context: context)

    try addOpacityAnimation(for: fill, context: context)
  }

  
  @nonobjc
  func addAnimations(for trim: Trim, context: LayerAnimationContext) throws {
    let (strokeStartKeyframes, strokeEndKeyframes) = trim.caShapeLayerKeyframes()

    if trim.offset.keyframes.contains(where: { $0.value.cgFloatValue != 0 }) {
      try context.logCompatibilityIssue("""
        The CoreAnimation rendering engine doesn't support Trim offsets
        """)
    }

    try addAnimation(
      for: .strokeStart,
      keyframes: strokeStartKeyframes.keyframes,
      value: { strokeStart in
        
        
        
        CGFloat(strokeStart.cgFloatValue) / 100
      }, context: context)

    try addAnimation(
      for: .strokeEnd,
      keyframes: strokeEndKeyframes.keyframes,
      value: { strokeEnd in
        
        
        
        CGFloat(strokeEnd.cgFloatValue) / 100
      }, context: context)
  }
}

extension Trim {

  

  
  
  
  
  
  
  fileprivate func caShapeLayerKeyframes()
    -> (strokeStart: KeyframeGroup<Vector1D>, strokeEnd: KeyframeGroup<Vector1D>)
  {
    if startValueIsAlwaysGreaterThanEndValue() {
      return (strokeStart: end, strokeEnd: start)
    } else {
      return (strokeStart: start, strokeEnd: end)
    }
  }

  

  
  
  private func startValueIsAlwaysGreaterThanEndValue() -> Bool {
    let keyframeTimes = Set(start.keyframes.map { $0.time } + end.keyframes.map { $0.time })

    let startInterpolator = KeyframeInterpolator(keyframes: start.keyframes)
    let endInterpolator = KeyframeInterpolator(keyframes: end.keyframes)

    for keyframeTime in keyframeTimes {
      guard
        let startAtTime = startInterpolator.value(frame: keyframeTime) as? Vector1D,
        let endAtTime = endInterpolator.value(frame: keyframeTime) as? Vector1D
      else { continue }

      if startAtTime.cgFloatValue < endAtTime.cgFloatValue {
        return false
      }
    }

    return true
  }
}
