


import QuartzCore



final class SolidLayer: BaseCompositionLayer {

  

  init(_ solidLayer: SolidLayerModel) {
    self.solidLayer = solidLayer
    super.init(layerModel: solidLayer)
    setupContentLayer()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    solidLayer = typedLayer.solidLayer
    super.init(layer: typedLayer)
  }

  

  private let solidLayer: SolidLayerModel

  private func setupContentLayer() {
    
    
    
    let shapeLayer = CAShapeLayer()
    shapeLayer.fillColor = solidLayer.colorHex.cgColor
    shapeLayer.path = CGPath(rect: .init(x: 0, y: 0, width: solidLayer.width, height: solidLayer.height), transform: nil)
    addSublayer(shapeLayer)
  }

}
