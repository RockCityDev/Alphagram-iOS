






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit


public class FilepathImageProvider: AnimationImageProvider {

  

  
  
  
  
  public init(filepath: String) {
    self.filepath = URL(fileURLWithPath: filepath)
  }

  public init(filepath: URL) {
    self.filepath = filepath
  }

  

  public func imageForAsset(asset: ImageAsset) -> CGImage? {

    if
      asset.name.hasPrefix("data:"),
      let url = URL(string: asset.name),
      let data = try? Data(contentsOf: url),
      let image = UIImage(data: data)
    {
      return image.cgImage
    }

    let directPath = filepath.appendingPathComponent(asset.name).path
    if FileManager.default.fileExists(atPath: directPath) {
      return UIImage(contentsOfFile: directPath)?.cgImage
    }

    let pathWithDirectory = filepath.appendingPathComponent(asset.directory).appendingPathComponent(asset.name).path
    if FileManager.default.fileExists(atPath: pathWithDirectory) {
      return UIImage(contentsOfFile: pathWithDirectory)?.cgImage
    }

    LottieLogger.shared.assertionFailure("Could not find image \"\(asset.name)\" in bundle")
    return nil
  }

  

  let filepath: URL
}
#endif
