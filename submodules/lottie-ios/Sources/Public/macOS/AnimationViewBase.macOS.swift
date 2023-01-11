






#if os(macOS)
import AppKit

public enum LottieContentMode: Int {
  case scaleToFill
  case scaleAspectFit
  case scaleAspectFill
  case redraw
  case center
  case top
  case bottom
  case left
  case right
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
}




public class AnimationViewBase: NSView {

  

  public override var wantsUpdateLayer: Bool {
    true
  }

  public override var isFlipped: Bool {
    true
  }

  public var contentMode: LottieContentMode = .scaleAspectFit {
    didSet {
      setNeedsLayout()
    }
  }

  public override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    animationMovedToWindow()
  }

  public override func layout() {
    super.layout()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layoutAnimation()
    CATransaction.commit()
  }

  

  var screenScale: CGFloat {
    NSApp.mainWindow?.backingScaleFactor ?? 1
  }

  var viewLayer: CALayer? {
    layer
  }

  func layoutAnimation() {
    
  }

  func animationMovedToWindow() {
    
  }

  func commonInit() {
    wantsLayer = true
  }

  func setNeedsLayout() {
    needsLayout = true
  }

  func layoutIfNeeded() {
    
  }

  @objc
  func animationWillMoveToBackground() {
    
  }

  @objc
  func animationWillEnterForeground() {
    
  }

}
#endif
