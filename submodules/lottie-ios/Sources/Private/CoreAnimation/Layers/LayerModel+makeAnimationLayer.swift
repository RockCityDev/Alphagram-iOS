


import QuartzCore




struct LayerContext {
  let animation: Animation
  let imageProvider: AnimationImageProvider
  let fontProvider: AnimationFontProvider
  let compatibilityTracker: CompatibilityTracker
  var layerName: String

  func forLayer(_ layer: LayerModel) -> LayerContext {
    var context = self
    context.layerName = layer.name
    return context
  }
}



extension LayerModel {
  
  func makeAnimationLayer(context: LayerContext) throws -> BaseCompositionLayer? {
    let context = context.forLayer(self)

    switch (type, self) {
    case (.precomp, let preCompLayerModel as PreCompLayerModel):
      let preCompLayer = PreCompLayer(preCompLayer: preCompLayerModel)
      try preCompLayer.setup(context: context)
      return preCompLayer

    case (.solid, let solidLayerModel as SolidLayerModel):
      return SolidLayer(solidLayerModel)

    case (.shape, let shapeLayerModel as ShapeLayerModel):
      return try ShapeLayer(shapeLayer: shapeLayerModel, context: context)

    case (.image, let imageLayerModel as ImageLayerModel):
      return ImageLayer(imageLayer: imageLayerModel, context: context)

    case (.text, let textLayerModel as TextLayerModel):
      return try TextLayer(textLayerModel: textLayerModel, context: context)

    case (.null, _):
      return TransformLayer(layerModel: self)

    default:
      try context.logCompatibilityIssue("""
        Unexpected layer type combination ("\(type)" and "\(Swift.type(of: self))")
        """)

      return nil
    }
  }

}
