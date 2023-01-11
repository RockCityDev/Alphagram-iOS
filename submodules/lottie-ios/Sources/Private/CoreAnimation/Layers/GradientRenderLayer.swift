


import QuartzCore

















final class GradientRenderLayer: CAGradientLayer {

  

  
  
  var gradientReferenceBounds: CGRect = .zero {
    didSet {
      if oldValue != gradientReferenceBounds {
        updateLayout()
      }
    }
  }

  
  
  
  
  
  func percentBasedPointInBounds(from referencePoint: CGPoint) -> CGPoint {
    guard bounds.width > 0, bounds.height > 0 else {
      LottieLogger.shared.assertionFailure("Size must be non-zero before an animation can be played")
      return .zero
    }

    let pointInBounds = CGPoint(
      x: referencePoint.x + gradientPadding,
      y: referencePoint.y + gradientPadding)

    return CGPoint(
      x: CGFloat(pointInBounds.x) / bounds.width,
      y: CGFloat(pointInBounds.y) / bounds.height)
  }

  

  
  
  ///    Theoretically this should be "infinite", to match the behavior of
  
  private let gradientPadding: CGFloat = 2_000

  private func updateLayout() {
    anchorPoint = .zero

    bounds = CGRect(
      x: gradientReferenceBounds.origin.x,
      y: gradientReferenceBounds.origin.y,
      width: gradientPadding + gradientReferenceBounds.width + gradientPadding,
      height: gradientPadding + gradientReferenceBounds.height + gradientPadding)

    transform = CATransform3DMakeTranslation(
      -gradientPadding,
      -gradientPadding,
      0)
  }

}



extension GradientRenderLayer: CustomLayoutLayer {
  func layout(superlayerBounds: CGRect) {
    gradientReferenceBounds = superlayerBounds
  }
}
