


import QuartzCore


final class TextLayer: BaseCompositionLayer {

  

  init(
    textLayerModel: TextLayerModel,
    context: LayerContext)
    throws
  {
    self.textLayerModel = textLayerModel
    super.init(layerModel: textLayerModel)
    setupSublayers()
    try configureRenderLayer(with: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    textLayerModel = typedLayer.textLayerModel
    super.init(layer: typedLayer)
  }

  

  func configureRenderLayer(with context: LayerContext) throws {
    
    
    
    
    let text = try textLayerModel.text.exactlyOneKeyframe(context: context, description: "text layer text").value

    
    
    
    
    
    if !textLayerModel.animators.isEmpty {
      try context.logCompatibilityIssue("""
        The Core Animation rendering engine currently doesn't support text animators.
        """)
    }

    renderLayer.text = text.text
    renderLayer.font = context.fontProvider.fontFor(family: text.fontFamily, size: CGFloat(text.fontSize))

    renderLayer.alignment = text.justification.textAlignment
    renderLayer.lineHeight = CGFloat(text.lineHeight)
    renderLayer.tracking = (CGFloat(text.fontSize) * CGFloat(text.tracking)) / 1000

    renderLayer.fillColor = text.fillColorData?.cgColorValue
    renderLayer.strokeColor = text.strokeColorData?.cgColorValue
    renderLayer.strokeWidth = CGFloat(text.strokeWidth ?? 0)
    renderLayer.strokeOnTop = text.strokeOverFill ?? false

    renderLayer.preferredSize = text.textFrameSize?.sizeValue
    renderLayer.sizeToFit()

    renderLayer.transform = CATransform3DIdentity
    renderLayer.position = text.textFramePosition?.pointValue ?? .zero
  }

  

  private let textLayerModel: TextLayerModel
  private let renderLayer = CoreTextRenderLayer()

  private func setupSublayers() {
    
    
    
    
    let textContainerLayer = CALayer()
    textContainerLayer.addSublayer(renderLayer)
    addSublayer(textContainerLayer)
  }

}
