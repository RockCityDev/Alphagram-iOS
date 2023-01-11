


import QuartzCore




class BaseCompositionLayer: BaseAnimationLayer {

  

  init(layerModel: LayerModel) {
    baseLayerModel = layerModel
    super.init()

    setupSublayers()
    compositingFilter = layerModel.blendMode.filterName
    name = layerModel.name
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    baseLayerModel = typedLayer.baseLayerModel
    super.init(layer: typedLayer)
  }

  

  
  var renderLayerContents: Bool { true }

  
  
  
  override func setupAnimations(context: LayerAnimationContext) throws {
    var context = context
    if renderLayerContents {
      context = context.addingKeypathComponent(baseLayerModel.name)
    }

    try setupLayerAnimations(context: context)
    try setupChildAnimations(context: context)
  }

  func setupLayerAnimations(context: LayerAnimationContext) throws {
    let context = context.addingKeypathComponent(baseLayerModel.name)

    try addTransformAnimations(for: baseLayerModel.transform, context: context)

    if renderLayerContents {
      try addOpacityAnimation(for: baseLayerModel.transform, context: context)

      addVisibilityAnimation(
        inFrame: CGFloat(baseLayerModel.inFrame),
        outFrame: CGFloat(baseLayerModel.outFrame),
        context: context)
    }
  }

  func setupChildAnimations(context: LayerAnimationContext) throws {
    try super.setupAnimations(context: context)
  }

  

  private let baseLayerModel: LayerModel

  private func setupSublayers() {
    if
      renderLayerContents,
      let masks = baseLayerModel.masks
    {
      mask = MaskCompositionLayer(masks: masks)
    }
  }

}
