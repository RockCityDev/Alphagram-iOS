






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit


public final class AnimationSubview: UIView {

  var viewLayer: CALayer? {
    layer
  }

}
#endif
