


import QuartzCore





final class ShapeItemLayer: BaseAnimationLayer {

  

  
  
  
  
  init(shape: Item, otherItems: [Item], context: LayerContext) throws {
    self.shape = shape
    self.otherItems = otherItems

    try context.compatibilityAssert(
      shape.item.drawsCGPath,
      "`ShapeItemLayer` must contain exactly one `ShapeItem` that draws a `GPPath`")

    try context.compatibilityAssert(
      !otherItems.contains(where: { $0.item.drawsCGPath }),
      "`ShapeItemLayer` must contain exactly one `ShapeItem` that draws a `GPPath`")

    super.init()

    setupLayerHierarchy()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    shape = typedLayer.shape
    otherItems = typedLayer.otherItems
    super.init(layer: typedLayer)
  }

  

  
  struct Item {
    
    let item: ShapeItem

    
    let parentGroup: Group?
  }

  override func setupAnimations(context: LayerAnimationContext) throws {
    try super.setupAnimations(context: context)

    guard let sublayerConfiguration = sublayerConfiguration else { return }

    switch sublayerConfiguration.fill {
    case .solidFill(let shapeLayer):
      try setupSolidFillAnimations(shapeLayer: shapeLayer, context: context)

    case .gradientFill(let gradientLayers):
      try setupGradientFillAnimations(
        gradientLayer: gradientLayers.gradientLayer,
        maskLayer: gradientLayers.maskLayer,
        context: context)
    }

    if let gradientStrokeConfiguration = sublayerConfiguration.gradientStroke {
      try setupGradientStrokeAnimations(
        gradientLayer: gradientStrokeConfiguration.gradientLayer,
        maskLayer: gradientStrokeConfiguration.maskLayer,
        context: context)
    }
  }

  

  private struct GradientLayers {
    
    let gradientLayer: GradientRenderLayer
    
    let maskLayer: CAShapeLayer
  }

  
  private enum FillLayerConfiguration {
    
    case solidFill(CAShapeLayer)

    
    case gradientFill(GradientLayers)
  }

  
  private let shape: Item

  
  private let otherItems: [Item]

  
  private var sublayerConfiguration: (fill: FillLayerConfiguration, gradientStroke: GradientLayers?)?

  private func setupLayerHierarchy() {
    
    
    
    let fillLayerConfiguration: FillLayerConfiguration
    if otherItems.contains(where: { $0.item is GradientFill }) {
      fillLayerConfiguration = setupGradientFillLayerHierarchy()
    } else {
      fillLayerConfiguration = setupSolidFillLayerHierarchy()
    }

    let gradientStrokeConfiguration: GradientLayers?
    if otherItems.contains(where: { $0.item is GradientStroke }) {
      gradientStrokeConfiguration = setupGradientStrokeLayerHierarchy()
    } else {
      gradientStrokeConfiguration = nil
    }

    sublayerConfiguration = (fillLayerConfiguration, gradientStrokeConfiguration)
  }

  private func setupSolidFillLayerHierarchy() -> FillLayerConfiguration {
    let shapeLayer = CAShapeLayer()
    addSublayer(shapeLayer)

    
    
    if !otherItems.contains(where: { $0.item is Fill }) {
      shapeLayer.fillColor = nil
    }

    return .solidFill(shapeLayer)
  }

  private func setupGradientFillLayerHierarchy() -> FillLayerConfiguration {
    let pathMask = CAShapeLayer()
    pathMask.fillColor = .rgb(0, 0, 0)
    mask = pathMask

    let gradientLayer = GradientRenderLayer()
    addSublayer(gradientLayer)

    return .gradientFill(.init(gradientLayer: gradientLayer, maskLayer: pathMask))
  }

  private func setupGradientStrokeLayerHierarchy() -> GradientLayers {
    let container = BaseAnimationLayer()

    let pathMask = CAShapeLayer()
    pathMask.fillColor = nil
    pathMask.strokeColor = .rgb(0, 0, 0)
    container.mask = pathMask

    let gradientLayer = GradientRenderLayer()
    container.addSublayer(gradientLayer)
    addSublayer(container)

    return .init(gradientLayer: gradientLayer, maskLayer: pathMask)
  }

  private func setupSolidFillAnimations(
    shapeLayer: CAShapeLayer,
    context: LayerAnimationContext)
    throws
  {
    try shapeLayer.addAnimations(for: shape.item, context: context.for(shape))

    if let (fill, context) = otherItems.first(Fill.self, context: context) {
      try shapeLayer.addAnimations(for: fill, context: context)
    }

    if let (stroke, context) = otherItems.first(Stroke.self, context: context) {
      try shapeLayer.addStrokeAnimations(for: stroke, context: context)
    }

    if let (trim, context) = otherItems.first(Trim.self, context: context) {
      try shapeLayer.addAnimations(for: trim, context: context)
    }
  }

  private func setupGradientFillAnimations(
    gradientLayer: GradientRenderLayer,
    maskLayer: CAShapeLayer,
    context: LayerAnimationContext)
    throws
  {
    try maskLayer.addAnimations(for: shape.item, context: context.for(shape))

    if let (gradientFill, context) = otherItems.first(GradientFill.self, context: context) {
      try gradientLayer.addGradientAnimations(for: gradientFill, context: context)
    }
  }

  private func setupGradientStrokeAnimations(
    gradientLayer: GradientRenderLayer,
    maskLayer: CAShapeLayer,
    context: LayerAnimationContext)
    throws
  {
    try maskLayer.addAnimations(for: shape.item, context: context.for(shape))

    if let (gradientStroke, context) = otherItems.first(GradientStroke.self, context: context) {
      try gradientLayer.addGradientAnimations(for: gradientStroke, context: context)
      try maskLayer.addStrokeAnimations(for: gradientStroke, context: context)
    }

    if let (trim, context) = otherItems.first(Trim.self, context: context) {
      try maskLayer.addAnimations(for: trim, context: context)
    }
  }

}



extension Array where Element == ShapeItemLayer.Item {
  
  func first<ItemType: ShapeItem>(
    _: ItemType.Type, context: LayerAnimationContext)
    -> (item: ItemType, context: LayerAnimationContext)?
  {
    for item in self {
      if let match = item.item as? ItemType {
        return (match, context.for(item))
      }
    }

    return nil
  }
}

extension LayerAnimationContext {
  
  
  func `for`(_ item: ShapeItemLayer.Item) -> LayerAnimationContext {
    var context = self

    if let group = item.parentGroup {
      context.currentKeypath.keys.append(group.name)
    }

    context.currentKeypath.keys.append(item.item.name)
    return context
  }
}
