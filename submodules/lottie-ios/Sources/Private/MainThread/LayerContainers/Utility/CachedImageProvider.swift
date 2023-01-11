


import CoreGraphics
import Foundation



private final class CachedImageProvider: AnimationImageProvider {

  

  
  
  
  
  public init(imageProvider: AnimationImageProvider) {
    self.imageProvider = imageProvider
  }

  

  public func imageForAsset(asset: ImageAsset) -> CGImage? {
    if let image = imageCache.object(forKey: asset.id as NSString) {
      return image
    }
    if let image = imageProvider.imageForAsset(asset: asset) {
      imageCache.setObject(image, forKey: asset.id as NSString)
      return image
    }
    return nil
  }

  

  let imageCache: NSCache<NSString, CGImage> = .init()
  let imageProvider: AnimationImageProvider
}

extension AnimationImageProvider {
  
  
  
  var cachedImageProvider: AnimationImageProvider {
    CachedImageProvider(imageProvider: self)
  }
}
