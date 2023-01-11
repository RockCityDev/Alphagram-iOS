


import QuartzCore



extension CALayer {
  
  
  @nonobjc
  func fillBoundsOfSuperlayer() {
    guard let superlayer = superlayer else { return }

    if let customLayerLayer = self as? CustomLayoutLayer {
      customLayerLayer.layout(superlayerBounds: superlayer.bounds)
    }

    else {
      
      
      
      anchorPoint = .zero

      bounds = superlayer.bounds
    }
  }
}




protocol CustomLayoutLayer: CALayer {
  func layout(superlayerBounds: CGRect)
}
