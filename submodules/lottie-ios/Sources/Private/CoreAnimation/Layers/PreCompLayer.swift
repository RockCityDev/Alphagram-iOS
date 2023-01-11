


import QuartzCore




final class PreCompLayer: BaseCompositionLayer {

  

  init(preCompLayer: PreCompLayerModel) {
    self.preCompLayer = preCompLayer
    super.init(layerModel: preCompLayer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    preCompLayer = typedLayer.preCompLayer
    timeRemappingInterpolator = typedLayer.timeRemappingInterpolator
    super.init(layer: typedLayer)
  }

  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  func setup(context: LayerContext) throws {
    if let timeRemappingKeyframes = preCompLayer.timeRemapping {
      timeRemappingInterpolator = try .timeRemapping(keyframes: timeRemappingKeyframes, context: context)
    } else {
      timeRemappingInterpolator = nil
    }

    try setupLayerHierarchy(
      for: context.animation.assetLibrary?.precompAssets[preCompLayer.referenceID]?.layers ?? [],
      context: context)
  }

  override func setupAnimations(context: LayerAnimationContext) throws {
    var context = context
    context = context.addingKeypathComponent(preCompLayer.name)
    try setupLayerAnimations(context: context)

    
    
    let contextForChildren = context.withTimeRemapping { [preCompLayer, timeRemappingInterpolator] layerLocalFrame in
      if let timeRemappingInterpolator = timeRemappingInterpolator {
        return timeRemappingInterpolator.value(frame: layerLocalFrame) as? AnimationFrameTime ?? layerLocalFrame
      } else {
        return layerLocalFrame + AnimationFrameTime(preCompLayer.startTime)
      }
    }

    try setupChildAnimations(context: contextForChildren)
  }

  

  private let preCompLayer: PreCompLayerModel
  private var timeRemappingInterpolator: KeyframeInterpolator<AnimationFrameTime>?

}



extension PreCompLayer: CustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    anchorPoint = .zero

    
    
    bounds = CGRect(
      x: superlayerBounds.origin.x,
      y: superlayerBounds.origin.y,
      width: CGFloat(preCompLayer.width),
      height: CGFloat(preCompLayer.height))

    masksToBounds = true
  }
}

extension KeyframeInterpolator where ValueType == AnimationFrameTime {
  
  static func timeRemapping(
    keyframes timeRemappingKeyframes: KeyframeGroup<Vector1D>,
    context: LayerContext)
    throws
    -> KeyframeInterpolator<AnimationFrameTime>
  {
    try context.logCompatibilityIssue("""
      The Core Animation rendering engine partially supports time remapping keyframes,
      but this is somewhat experimental and has some known issues. Since it doesn't work
      in all cases, we have to fall back to using the main thread engine when using
      `RenderingEngineOption.automatic`.
      """)

    
    
    
    
    let localTimeToGlobalTimeMapping = timeRemappingKeyframes.keyframes.map { keyframe in
      Keyframe(
        value: keyframe.time,
        time: keyframe.value.cgFloatValue * CGFloat(context.animation.framerate),
        isHold: keyframe.isHold,
        inTangent: keyframe.inTangent,
        outTangent: keyframe.outTangent,
        spatialInTangent: keyframe.spatialInTangent,
        spatialOutTangent: keyframe.spatialOutTangent)
    }

    return KeyframeInterpolator(keyframes: .init(localTimeToGlobalTimeMapping))
  }
}
