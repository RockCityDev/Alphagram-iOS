






import Foundation









/// of objects. Acceptable wildcards are either "*" (star) or "**" (double star).






/// @"Layer.Shape Group.Stroke 1.Color"


/// @"**.Stroke 1.Color"
/// Represents the color node for every Stroke named "Stroke 1" in the animation.
public struct AnimationKeypath: Hashable, ExpressibleByStringLiteral {

  /// Creates a keypath from a dot-separated string. The string is separated by "."
  public init(keypath: String) {
    keys = keypath.components(separatedBy: ".")
  }

  
  public init(stringLiteral: String) {
    self.init(keypath: stringLiteral)
  }

  
  public init(keys: [String]) {
    self.keys = keys
  }

  public var keys: [String]

}
