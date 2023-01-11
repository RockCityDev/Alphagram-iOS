


import QuartzCore



class BaseAnimationLayer: CALayer, AnimationLayer {

  

  override func layoutSublayers() {
    super.layoutSublayers()

    for sublayer in managedSublayers {
      sublayer.fillBoundsOfSuperlayer()
    }
  }

  func setupAnimations(context: LayerAnimationContext) throws {
    for childAnimationLayer in managedSublayers {
      try (childAnimationLayer as? AnimationLayer)?.setupAnimations(context: context)
    }
  }

  

  
  private var managedSublayers: [CALayer] {
    (sublayers ?? []) + [mask].compactMap { $0 }
  }

}
