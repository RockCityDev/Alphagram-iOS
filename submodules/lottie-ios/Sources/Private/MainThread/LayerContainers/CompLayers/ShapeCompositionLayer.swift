






import CoreGraphics
import Foundation


final class ShapeCompositionLayer: CompositionLayer {

  

  init(shapeLayer: ShapeLayerModel) {
    let results = shapeLayer.items.initializeNodeTree()
    let renderContainer = ShapeContainerLayer()
    self.renderContainer = renderContainer
    rootNode = results.rootNode
    super.init(layer: shapeLayer, size: .zero)
    contentsLayer.addSublayer(renderContainer)
    for container in results.renderContainers {
      renderContainer.insertRenderLayer(container)
    }
    rootNode?.updateTree(0, forceUpdates: true)
    childKeypaths.append(contentsOf: results.childrenNodes)
  }

  override init(layer: Any) {
    guard let layer = layer as? ShapeCompositionLayer else {
      fatalError("init(layer:) wrong class.")
    }
    rootNode = nil
    renderContainer = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  let rootNode: AnimatorNode?
  let renderContainer: ShapeContainerLayer?

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    rootNode?.updateTree(frame, forceUpdates: forceUpdates)
    renderContainer?.markRenderUpdates(forFrame: frame)
  }

  override func updateRenderScale() {
    super.updateRenderScale()
    renderContainer?.renderScale = renderScale
  }

}
