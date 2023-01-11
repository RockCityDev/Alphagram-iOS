import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

extension Bundle {
  func getAnimationData(_ name: String, subdirectory: String? = nil) throws -> Data? {
    
    let name = name.removingJSONSuffix()
    if let url = url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
      return try Data(contentsOf: url)
    }

    
    #if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
    let assetKey = subdirectory != nil ? "\(subdirectory ?? "")/\(name)" : name
    return NSDataAsset(name: assetKey, bundle: self)?.data
    #else
    return nil
    #endif
  }
}

extension String {
  fileprivate func removingJSONSuffix() -> String {
    // Allow filenames to be passed with a ".json" extension (but not other extensions)
    
    guard hasSuffix(".json") else {
      return self
    }

    return (self as NSString).deletingPathExtension
  }
}
