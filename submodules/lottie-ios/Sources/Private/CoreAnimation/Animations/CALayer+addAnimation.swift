


import QuartzCore
import UIKit

extension CALayer {

  

  
  
  @nonobjc
  func addAnimation<KeyframeValue, ValueRepresentation: Equatable>(
    for property: LayerProperty<ValueRepresentation>,
    keyframes: ContiguousArray<Keyframe<KeyframeValue>>,
    value keyframeValueMapping: (KeyframeValue) throws -> ValueRepresentation,
    context: LayerAnimationContext)
    throws
  {
    if let customAnimation = try customizedAnimation(for: property, context: context) {
      add(customAnimation, timedWith: context)
    }

    else if
      let defaultAnimation = try defaultAnimation(
        for: property,
        keyframes: keyframes,
        value: keyframeValueMapping,
        context: context)
    {
      add(defaultAnimation, timedWith: context)
    }
  }

  

  
  
  
  @nonobjc
  private func defaultAnimation<KeyframeValue, ValueRepresentation>(
    for property: LayerProperty<ValueRepresentation>,
    keyframes: ContiguousArray<Keyframe<KeyframeValue>>,
    value keyframeValueMapping: (KeyframeValue) throws -> ValueRepresentation,
    context: LayerAnimationContext)
    throws
    -> CAPropertyAnimation?
  {
    guard !keyframes.isEmpty else { return nil }

    
    
    
    if keyframes.count == 1 {
      let keyframeValue = try keyframeValueMapping(keyframes[0].value)

      
      
      if keyframeValue == property.defaultValue {
        return nil
      }

      
      
      
      if
        let defaultValue = property.defaultValue,
        defaultValue == value(forKey: property.caLayerKeypath) as? ValueRepresentation
      {
        setValue(keyframeValue, forKeyPath: property.caLayerKeypath)
        return nil
      }

      
      
      
      let animation = CABasicAnimation(keyPath: property.caLayerKeypath)
      animation.fromValue = keyframeValue
      animation.toValue = keyframeValue
      if #available(iOS 15.0, *) {
        let maxFps = Float(UIScreen.main.maximumFramesPerSecond)
        if maxFps > 61.0 {
          animation.preferredFrameRateRange = CAFrameRateRange(minimum: maxFps, maximum: maxFps, preferred: maxFps)
        }
      }
      return animation
    }

    return try keyframeAnimation(
      for: property,
      keyframes: keyframes,
      value: keyframeValueMapping,
      context: context)
  }

  
  
  
  @nonobjc
  private func customizedAnimation<ValueRepresentation>(
    for property: LayerProperty<ValueRepresentation>,
    context: LayerAnimationContext)
    throws
    -> CAPropertyAnimation?
  {
    guard
      let customizableProperty = property.customizableProperty,
      let customKeyframes = try context.valueProviderStore.customKeyframes(
        of: customizableProperty,
        for: AnimationKeypath(keys: context.currentKeypath.keys + customizableProperty.name.map { $0.rawValue }),
        context: context)
    else { return nil }

    
    
    
    return try keyframeAnimation(
      for: property,
      keyframes: customKeyframes.keyframes,
      value: { $0 },
      context: context)
  }

  
  private func keyframeAnimation<KeyframeValue, ValueRepresentation>(
    for property: LayerProperty<ValueRepresentation>,
    keyframes: ContiguousArray<Keyframe<KeyframeValue>>,
    value keyframeValueMapping: (KeyframeValue) throws -> ValueRepresentation,
    context: LayerAnimationContext)
    throws
    -> CAKeyframeAnimation
  {
    
    
    var keyTimes = keyframes.map { keyframeModel -> NSNumber in
      NSNumber(value: Float(context.progressTime(for: keyframeModel.time)))
    }

    var timingFunctions = self.timingFunctions(for: keyframes)
    let calculationMode = try self.calculationMode(for: keyframes, context: context)

    let animation = CAKeyframeAnimation(keyPath: property.caLayerKeypath)
    if #available(iOS 15.0, *) {
      let maxFps = Float(UIScreen.main.maximumFramesPerSecond)
      if maxFps > 61.0 {
        animation.preferredFrameRateRange = CAFrameRateRange(minimum: maxFps, maximum: maxFps, preferred: maxFps)
      }
    }

    
    
    if property.caLayerKeypath == LayerProperty<CGPoint>.position.caLayerKeypath {
      animation.path = try path(keyframes: keyframes, value: { value in
        guard let point = try keyframeValueMapping(value) as? CGPoint else {
          LottieLogger.shared.assertionFailure("Cannot create point from keyframe with value \(value)")
          return .zero
        }

        return point
      })
    }

    
    else {
      var values = try keyframes.map { keyframeModel in
        try keyframeValueMapping(keyframeModel.value)
      }

      validate(values: &values, keyTimes: &keyTimes, timingFunctions: &timingFunctions, for: calculationMode)
      animation.values = values
    }

    animation.calculationMode = calculationMode
    animation.keyTimes = keyTimes
    animation.timingFunctions = timingFunctions
    return animation
  }

  
  
  private func calculationMode<KeyframeValue>(
    for keyframes: ContiguousArray<Keyframe<KeyframeValue>>,
    context: LayerAnimationContext)
    throws
    -> CAAnimationCalculationMode
  {
    
    
    
    
    
    
    
    
    
    
    
    let intermediateKeyframes = keyframes.dropFirst().dropLast()
    if intermediateKeyframes.contains(where: \.isHold) {
      if intermediateKeyframes.allSatisfy(\.isHold) {
        return .discrete
      } else {
        try context.logCompatibilityIssue("Mixed `isHold` / `!isHold` keyframes are currently unsupported")
      }
    }

    return .linear
  }

  
  private func timingFunctions<KeyframeValue>(
    for keyframes: ContiguousArray<Keyframe<KeyframeValue>>)
    -> [CAMediaTimingFunction]
  {
    
    var timingFunctions: [CAMediaTimingFunction] = []

    for (index, keyframe) in keyframes.enumerated()
      where index != keyframes.indices.last
    {
      let nextKeyframe = keyframes[index + 1]

      let controlPoint1 = keyframe.outTangent?.pointValue ?? .zero
      let controlPoint2 = nextKeyframe.inTangent?.pointValue ?? CGPoint(x: 1, y: 1)

      timingFunctions.append(CAMediaTimingFunction(
        controlPoints:
        Float(controlPoint1.x),
        Float(controlPoint1.y),
        Float(controlPoint2.x),
        Float(controlPoint2.y)))
    }

    return timingFunctions
  }

  
  
  private func path<KeyframeValue>(
    keyframes positionKeyframes: ContiguousArray<Keyframe<KeyframeValue>>,
    value keyframeValueMapping: (KeyframeValue) throws -> CGPoint) rethrows
    -> CGPath {
    let path = CGMutablePath()

    for (index, keyframe) in positionKeyframes.enumerated() {
      if index == positionKeyframes.indices.first {
        path.move(to: try keyframeValueMapping(keyframe.value))
      }

      if index != positionKeyframes.indices.last {
        let nextKeyframe = positionKeyframes[index + 1]

        if
          let controlPoint1 = keyframe.spatialOutTangent?.pointValue,
          let controlPoint2 = nextKeyframe.spatialInTangent?.pointValue,
          controlPoint1 != .zero,
          controlPoint2 != .zero
        {
          path.addCurve(
            to: try keyframeValueMapping(nextKeyframe.value),
            control1: try keyframeValueMapping(keyframe.value) + controlPoint1,
            control2: try keyframeValueMapping(nextKeyframe.value) + controlPoint2)
        }

        else {
          path.addLine(to: try keyframeValueMapping(nextKeyframe.value))
        }
      }
    }

    path.closeSubpath()
    return path
  }

  
  private func validate<ValueRepresentation>(
    values: inout [ValueRepresentation],
    keyTimes: inout [NSNumber],
    timingFunctions: inout [CAMediaTimingFunction],
    for calculationMode: CAAnimationCalculationMode)
  {
    
    
    
    if keyTimes.first != 0.0 {
      keyTimes.insert(0.0, at: 0)
      values.insert(values[0], at: 0)
      timingFunctions.insert(CAMediaTimingFunction(name: .linear), at: 0)
    }

    if keyTimes.last != 1.0 {
      keyTimes.append(1.0)
      values.append(values.last!)
      timingFunctions.append(CAMediaTimingFunction(name: .linear))
    }

    switch calculationMode {
    case .linear, .cubic:
      
      
      
      LottieLogger.shared.assert(
        values.count == keyTimes.count,
        "`values.count` must exactly equal `keyTimes.count`")

      LottieLogger.shared.assert(
        timingFunctions.count == (values.count - 1),
        "`timingFunctions.count` must exactly equal `values.count - 1`")

    case .discrete:
      
      
      
      values.removeLast()

      LottieLogger.shared.assert(
        keyTimes.count == values.count + 1,
        "`keyTimes.count` must exactly equal `values.count + 1`")

    default:
      LottieLogger.shared.assertionFailure("""
        Unexpected keyframe calculation mode \(calculationMode)
        """)
    }
  }

}
