






import CoreGraphics
import Foundation
import QuartzCore

final class ImageCompositionLayer: CompositionLayer {

  

  init(imageLayer: ImageLayerModel, size: CGSize) {
    imageReferenceID = imageLayer.referenceID
    super.init(layer: imageLayer, size: size)
    contentsLayer.masksToBounds = true
    contentsLayer.contentsGravity = CALayerContentsGravity.resize
  }

  override init(layer: Any) {
    
    guard let layer = layer as? ImageCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    imageReferenceID = layer.imageReferenceID
    image = nil
    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  let imageReferenceID: String

  var image: CGImage? = nil {
    didSet {
      if let image = image {
        contentsLayer.contents = image
      } else {
        contentsLayer.contents = nil
      }
    }
  }
}
