


import QuartzCore




final class ImageLayer: BaseCompositionLayer {

  

  init(
    imageLayer: ImageLayerModel,
    context: LayerContext)
  {
    self.imageLayer = imageLayer
    super.init(layerModel: imageLayer)
    setupImage(context: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    imageLayer = typedLayer.imageLayer
    super.init(layer: typedLayer)
  }

  

  func setupImage(context: LayerContext) {
    guard
      let imageAsset = context.animation.assetLibrary?.imageAssets[imageLayer.referenceID],
      let image = context.imageProvider.imageForAsset(asset: imageAsset)
    else {
      self.imageAsset = nil
      contents = nil
      return
    }

    self.imageAsset = imageAsset
    contents = image
    setNeedsLayout()
  }

  

  private let imageLayer: ImageLayerModel
  private var imageAsset: ImageAsset?

}



extension ImageLayer: CustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    anchorPoint = .zero

    guard let imageAsset = imageAsset else {
      bounds = superlayerBounds
      return
    }

    
    bounds = CGRect(
      x: superlayerBounds.origin.x,
      y: superlayerBounds.origin.y,
      width: CGFloat(imageAsset.width),
      height: CGFloat(imageAsset.height))
  }
}
