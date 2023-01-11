






#if os(macOS)
import AppKit


public class BundleImageProvider: AnimationImageProvider {

  

  
  
  
  
  
  
  
  
  public init(bundle: Bundle, searchPath: String?) {
    self.bundle = bundle
    self.searchPath = searchPath
  }

  

  public func imageForAsset(asset: ImageAsset) -> CGImage? {

    if
      let data = Data(imageAsset: asset),
      let image = NSImage(data: data)
    {
      return image.CGImage
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

    guard let foundPath = imagePath, let image = NSImage(contentsOfFile: foundPath) else {
      
      LottieLogger.shared.assertionFailure("Could not find image \"\(asset.name)\" in bundle")
      return nil
    }
    return image.CGImage
  }

  

  let bundle: Bundle
  let searchPath: String?
}

#endif
