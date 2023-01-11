






import Foundation

final class NullCompositionLayer: CompositionLayer {

  init(layer: LayerModel) {
    super.init(layer: layer, size: .zero)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(layer: Any) {
    
    guard let layer = layer as? NullCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    super.init(layer: layer)
  }

}
