


import QuartzCore








struct LayerProperty<ValueRepresentation: Equatable> {
  
  let caLayerKeypath: String

  
  
  
  
  let defaultValue: ValueRepresentation?

  
  
  let customizableProperty: CustomizableProperty<ValueRepresentation>?
}





struct CustomizableProperty<ValueRepresentation> {
  
  
  
  
  
  let name: [PropertyName]

  
  
  let conversion: (Any) -> ValueRepresentation?
}






enum PropertyName: String {
  case color = "Color"
}



extension LayerProperty {
  static var position: LayerProperty<CGPoint> {
    .init(
      caLayerKeypath: "transform.translation",
      defaultValue: CGPoint(x: 0, y: 0),
      customizableProperty: nil )
  }

  static var positionX: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.translation.x",
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var positionY: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.translation.y",
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var scale: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale",
      defaultValue: 1,
      customizableProperty: nil )
  }

  static var scaleX: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale.x",
      defaultValue: 1,
      customizableProperty: nil )
  }

  static var scaleY: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.scale.y",
      defaultValue: 1,
      customizableProperty: nil )
  }

  static var rotation: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.rotation",
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var rotationY: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: "transform.rotation.y",
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var anchorPoint: LayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CALayer.anchorPoint),
      
      
      defaultValue: nil,
      customizableProperty: nil )
  }

  static var opacity: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CALayer.opacity),
      defaultValue: 1,
      customizableProperty: nil )
  }
}



extension LayerProperty {
  static var path: LayerProperty<CGPath> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.path),
      defaultValue: nil,
      customizableProperty: nil )
  }

  static var fillColor: LayerProperty<CGColor> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.fillColor),
      defaultValue: nil,
      customizableProperty: .color)
  }

  static var lineWidth: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.lineWidth),
      defaultValue: 1,
      customizableProperty: nil )
  }

  static var lineDashPhase: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.lineDashPhase),
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var strokeColor: LayerProperty<CGColor> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeColor),
      defaultValue: nil,
      customizableProperty: .color)
  }

  static var strokeStart: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeStart),
      defaultValue: 0,
      customizableProperty: nil )
  }

  static var strokeEnd: LayerProperty<CGFloat> {
    .init(
      caLayerKeypath: #keyPath(CAShapeLayer.strokeEnd),
      defaultValue: 1,
      customizableProperty: nil )
  }
}



extension LayerProperty {
  static var colors: LayerProperty<[CGColor]> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.colors),
      defaultValue: nil,
      customizableProperty: nil )
  }

  static var locations: LayerProperty<[CGFloat]> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.locations),
      defaultValue: nil,
      customizableProperty: nil )
  }

  static var startPoint: LayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.startPoint),
      defaultValue: nil,
      customizableProperty: nil )
  }

  static var endPoint: LayerProperty<CGPoint> {
    .init(
      caLayerKeypath: #keyPath(CAGradientLayer.endPoint),
      defaultValue: nil,
      customizableProperty: nil )
  }
}



extension CustomizableProperty {
  static var color: CustomizableProperty<CGColor> {
    .init(
      name: [.color],
      conversion: { typeErasedValue in
        guard let color = typeErasedValue as? Color else {
          return nil
        }

        return .rgba(CGFloat(color.r), CGFloat(color.g), CGFloat(color.b), CGFloat(color.a))
      })
  }
}
