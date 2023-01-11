






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)


@objc
public final class CompatibleAnimationKeypath: NSObject {

  

  /// Creates a keypath from a dot separated string. The string is separated by "."
  @objc
  public init(keypath: String) {
    animationKeypath = AnimationKeypath(keypath: keypath)
  }

  
  @objc
  public init(keys: [String]) {
    animationKeypath = AnimationKeypath(keys: keys)
  }

  

  public let animationKeypath: AnimationKeypath
}
#endif
