


import QuartzCore




protocol GradientShapeItem: OpacityAnimationModel {
  var startPoint: KeyframeGroup<Vector3D> { get }
  var endPoint: KeyframeGroup<Vector3D> { get }
  var gradientType: GradientType { get }
  var numberOfColors: Int { get }
  var colors: KeyframeGroup<[Double]> { get }
}



extension GradientFill: GradientShapeItem { }



extension GradientStroke: GradientShapeItem { }



extension GradientRenderLayer {

  

  
  func addGradientAnimations(for gradient: GradientShapeItem, context: LayerAnimationContext) throws {
    
    
    colors = .init(
      repeating: CGColor.rgb(0, 0, 0),
      count: gradient.numberOfColors)

    try addAnimation(
      for: .colors,
      keyframes: gradient.colors.keyframes,
      value: { colorComponents in
        gradient.colorConfiguration(from: colorComponents).map { $0.color }
      },
      context: context)

    try addAnimation(
      for: .locations,
      keyframes: gradient.colors.keyframes,
      value: { colorComponents in
        gradient.colorConfiguration(from: colorComponents).map { $0.location }
      },
      context: context)

    try addOpacityAnimation(for: gradient, context: context)

    switch gradient.gradientType {
    case .linear:
      try addLinearGradientAnimations(for: gradient, context: context)
    case .radial:
      try addRadialGradientAnimations(for: gradient, context: context)
    case .none:
      break
    }
  }

  

  private func addLinearGradientAnimations(
    for gradient: GradientShapeItem,
    context: LayerAnimationContext)
    throws
  {
    type = .axial

    try addAnimation(
      for: .startPoint,
      keyframes: gradient.startPoint.keyframes,
      value: { absoluteStartPoint in
        percentBasedPointInBounds(from: absoluteStartPoint.pointValue)
      },
      context: context)

    try addAnimation(
      for: .endPoint,
      keyframes: gradient.endPoint.keyframes,
      value: { absoluteEndPoint in
        percentBasedPointInBounds(from: absoluteEndPoint.pointValue)
      },
      context: context)
  }

  private func addRadialGradientAnimations(for gradient: GradientShapeItem, context: LayerAnimationContext) throws {
    type = .radial

    
    
    
    
    let absoluteStartPoint = try gradient.startPoint
      .exactlyOneKeyframe(context: context, description: "gradient startPoint").value.pointValue

    let absoluteEndPoint = try gradient.endPoint
      .exactlyOneKeyframe(context: context, description: "gradient endPoint").value.pointValue

    startPoint = percentBasedPointInBounds(from: absoluteStartPoint)

    let radius = absoluteStartPoint.distanceTo(absoluteEndPoint)
    endPoint = percentBasedPointInBounds(
      from: CGPoint(
        x: absoluteStartPoint.x + radius,
        y: absoluteStartPoint.y + radius))
  }
}

extension GradientShapeItem {
  
  
  fileprivate func colorConfiguration(
    from colorComponents: [Double])
    -> [(color: CGColor, location: CGFloat)]
  {
    precondition(
      colorComponents.count >= numberOfColors * 4,
      "Each color must have RGB components and a location component")

    var cgColors = [(color: CGColor, location: CGFloat)]()

    
    
    for colorIndex in 0..<numberOfColors {
      let colorStartIndex = colorIndex * 4

      let location = CGFloat(colorComponents[colorStartIndex])

      let color = CGColor.rgb(
        CGFloat(colorComponents[colorStartIndex + 1]),
        CGFloat(colorComponents[colorStartIndex + 2]),
        CGFloat(colorComponents[colorStartIndex + 3]))

      cgColors.append((color, location))
    }

    return cgColors
  }
}
