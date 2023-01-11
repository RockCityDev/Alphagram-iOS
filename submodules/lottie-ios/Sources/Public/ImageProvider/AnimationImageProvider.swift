






import CoreGraphics
import Foundation









public protocol AnimationImageProvider {
  func imageForAsset(asset: ImageAsset) -> CGImage?
}
