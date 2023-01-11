






import Foundation


public struct AnimationKeypath {
  
  /// Creates a keypath from a dot separated string. The string is separated by "."
  public init(keypath: String) {
    self.keys = keypath.components(separatedBy: ".")
  }
  
  
  public init(keys: [String]) {
    self.keys = keys
  }
  
  let keys: [String]
  
}
