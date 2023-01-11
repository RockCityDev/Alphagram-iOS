







import CoreGraphics
import CoreText
import Foundation





public protocol AnimationFontProvider {
  func fontFor(family: String, size: CGFloat) -> CTFont?
}




public final class DefaultFontProvider: AnimationFontProvider {

  

  public init() {}

  

  public func fontFor(family: String, size: CGFloat) -> CTFont? {
    CTFontCreateWithName(family as CFString, size, nil)
  }
}
