






import Foundation
import QuartzCore

final class SolidCompositionLayer: CompositionLayer {

  

  init(solid: SolidLayerModel) {
    let components = solid.colorHex.hexColorComponents()
    colorProperty =
      NodeProperty(provider: SingleValueProvider(Color(
        r: Double(components.red),
        g: Double(components.green),
        b: Double(components.blue),
        a: 1)))

    super.init(layer: solid, size: .zero)
    solidShape.path = CGPath(rect: CGRect(x: 0, y: 0, width: solid.width, height: solid.height), transform: nil)
    contentsLayer.addSublayer(solidShape)
  }

  override init(layer: Any) {
    
    guard let layer = layer as? SolidCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    colorProperty = layer.colorProperty
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  let colorProperty: NodeProperty<Color>?
  let solidShape = CAShapeLayer()

  override var keypathProperties: [String: AnyNodeProperty] {
    guard let colorProperty = colorProperty else { return super.keypathProperties }
    return [PropertyName.color.rawValue : colorProperty]
  }

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates _: Bool) {
    guard let colorProperty = colorProperty else { return }
    colorProperty.update(frame: frame)
    solidShape.fillColor = colorProperty.value.cgColorValue
  }
}
