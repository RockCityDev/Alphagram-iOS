






import Foundation


final class LayerImageProvider {

  

  init(imageProvider: AnimationImageProvider, assets: [String: ImageAsset]?) {
    self.imageProvider = imageProvider
    imageLayers = [ImageCompositionLayer]()
    if let assets = assets {
      imageAssets = assets
    } else {
      imageAssets = [:]
    }
    reloadImages()
  }

  

  private(set) var imageLayers: [ImageCompositionLayer]
  let imageAssets: [String: ImageAsset]

  var imageProvider: AnimationImageProvider {
    didSet {
      reloadImages()
    }
  }

  func addImageLayers(_ layers: [ImageCompositionLayer]) {
    for layer in layers {
      if imageAssets[layer.imageReferenceID] != nil {
        
        imageLayers.append(layer)
      }
    }
  }

  func reloadImages() {
    for imageLayer in imageLayers {
      if let asset = imageAssets[imageLayer.imageReferenceID] {
        imageLayer.image = imageProvider.imageForAsset(asset: asset)
      }
    }
  }
}
