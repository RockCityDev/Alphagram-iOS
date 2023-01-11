






#if os(macOS)
import AppKit


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
      let image = NSImage(data: data)
    {
      return image.CGImage
    }

    let directPath = filepath.appendingPathComponent(asset.name).path
    if FileManager.default.fileExists(atPath: directPath) {

      return NSImage(contentsOfFile: directPath)?.CGImage
    }

    let pathWithDirectory = filepath.appendingPathComponent(asset.directory).appendingPathComponent(asset.name).path
    if FileManager.default.fileExists(atPath: pathWithDirectory) {
      return NSImage(contentsOfFile: pathWithDirectory)?.CGImage
    }

    LottieLogger.shared.assertionFailure("Could not find image \"\(asset.name)\" in bundle")
    return nil
  }

  

  let filepath: URL
}

extension NSImage {
  @nonobjc
  var CGImage: CGImage? {
    guard let imageData = tiffRepresentation else { return nil }
    guard let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
  }
}
#endif
