






#if os(macOS)
import AppKit


public final class AnimationSubview: NSView {

  var viewLayer: CALayer? {
    layer
  }

}
#endif
