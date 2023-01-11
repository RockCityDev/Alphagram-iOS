






import CoreGraphics
import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit



public class BundleImageProvider: AnimationImageProvider {

  

  
  
  
  
  
  
  
  
  public init(bundle: Bundle, searchPath: String?) {
    self.bundle = bundle
    self.searchPath = searchPath
  }

  

  public func imageForAsset(asset: ImageAsset) -> CGImage? {

    if
      let data = Data(imageAsset: asset),
      let image = UIImage(data: data)
    {
      return image.cgImage
    }

    let imagePath: String?
    
    if let searchPath = searchPath {
      
      var directoryPath = URL(fileURLWithPath: searchPath)
      directoryPath.appendPathComponent(asset.directory)

      if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: directoryPath.path) {
        
        imagePath = path
      } else if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: searchPath) {
        
        imagePath = path
      } else {
        imagePath = bundle.path(forResource: asset.name, ofType: nil)
      }
    } else {
      if let path = bundle.path(forResource: asset.name, ofType: nil, inDirectory: asset.directory) {
        
        imagePath = path
      } else {
        
        imagePath = bundle.path(forResource: asset.name, ofType: nil)
      }
    }

    if imagePath == nil {
      guard let image = UIImage(named: asset.name, in: bundle, compatibleWith: nil) else {
        LottieLogger.shared.assertionFailure("Could not find image \"\(asset.name)\" in bundle")
        return nil
      }
      return image.cgImage
    }

    guard let foundPath = imagePath, let image = UIImage(contentsOfFile: foundPath) else {
      
      LottieLogger.shared.assertionFailure("Could not find image \"\(asset.name)\" in bundle")
      return nil
    }
    return image.cgImage
  }

  

  let bundle: Bundle
  let searchPath: String?
}
#endif
