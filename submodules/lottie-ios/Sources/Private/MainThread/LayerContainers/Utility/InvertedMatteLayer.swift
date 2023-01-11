






import Foundation
import QuartzCore




final class InvertedMatteLayer: CALayer, CompositionLayerDelegate {

  

  init(inputMatte: CompositionLayer) {
    self.inputMatte = inputMatte
    super.init()
    inputMatte.layerDelegate = self
    anchorPoint = .zero
    bounds = inputMatte.bounds
    setNeedsDisplay()
  }

  override init(layer: Any) {
    guard let layer = layer as? InvertedMatteLayer else {
      fatalError("init(layer:) wrong class.")
    }
    inputMatte = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  let inputMatte: CompositionLayer?
  let wrapperLayer = CALayer()

  func frameUpdated(frame _: CGFloat) {
    displayIfNeeded()
  }

  override func draw(in ctx: CGContext) {
    guard let inputMatte = inputMatte else { return }
    guard let fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0, 0, 0, 1])
    else { return }
    ctx.setFillColor(fillColor)
    ctx.fill(bounds)
    ctx.setBlendMode(.destinationOut)
    inputMatte.render(in: ctx)
  }

}
