import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit
#endif

extension Bundle {
  func getAnimationData(_ name: String, subdirectory: String? = nil) throws -> Data? {
    
    if let url = self.url(forResource: name, withExtension: "json", subdirectory: subdirectory) {
      return try Data(contentsOf: url)
    }

    
    #if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
      let assetKey = subdirectory != nil ? "\(subdirectory ?? "")/\(name)" : name
      return NSDataAsset.init(name: assetKey, bundle: self)?.data
    #else
      return nil
    #endif
  }
}
