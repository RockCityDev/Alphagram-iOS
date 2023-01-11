


import Foundation
import QuartzCore




protocol StrokeShapeItem: OpacityAnimationModel {
  var strokeColor: KeyframeGroup<Color>? { get }
  var width: KeyframeGroup<Vector1D> { get }
  var lineCap: LineCap { get }
  var lineJoin: LineJoin { get }
  var miterLimit: Double { get }
  var dashPattern: [DashElement]? { get }
}



extension Stroke: StrokeShapeItem {
  var strokeColor: KeyframeGroup<Color>? { color }
}



extension GradientStroke: StrokeShapeItem {
  var strokeColor: KeyframeGroup<Color>? { nil }
}



extension CAShapeLayer {
  
  @nonobjc
  func addStrokeAnimations(for stroke: StrokeShapeItem, context: LayerAnimationContext) throws {
    lineJoin = stroke.lineJoin.caLineJoin
    lineCap = stroke.lineCap.caLineCap
    miterLimit = CGFloat(stroke.miterLimit)

    if let strokeColor = stroke.strokeColor {
      try addAnimation(
        for: .strokeColor,
        keyframes: strokeColor.keyframes,
        value: \.cgColorValue,
        context: context)
    }

    try addAnimation(
      for: .lineWidth,
      keyframes: stroke.width.keyframes,
      value: \.cgFloatValue,
      context: context)

    try addOpacityAnimation(for: stroke, context: context)

    if let (dashPattern, dashPhase) = stroke.dashPattern?.shapeLayerConfiguration {
      lineDashPattern = try dashPattern.map {
        try KeyframeGroup(keyframes: $0)
          .exactlyOneKeyframe(context: context, description: "stroke dashPattern").value.cgFloatValue as NSNumber
      }

      try addAnimation(
        for: .lineDashPhase,
        keyframes: dashPhase,
        value: \.cgFloatValue,
        context: context)
    }
  }
}
