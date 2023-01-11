






#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit




public class AnimationViewBase: UIView {

  

  public override var contentMode: UIView.ContentMode {
    didSet {
      setNeedsLayout()
    }
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    animationMovedToWindow()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    layoutAnimation()
  }

  

  var viewLayer: CALayer? {
    layer
  }

  var screenScale: CGFloat {
    UIScreen.main.scale
  }

  func layoutAnimation() {
    
  }

  func animationMovedToWindow() {
    
  }

  func commonInit() {
    contentMode = .scaleAspectFit
    clipsToBounds = true
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(animationWillEnterForeground),
      name: UIApplication.willEnterForegroundNotification,
      object: nil)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(animationWillMoveToBackground),
      name: UIApplication.didEnterBackgroundNotification,
      object: nil)
  }

  @objc
  func animationWillMoveToBackground() {
    
  }

  @objc
  func animationWillEnterForeground() {
    
  }

}
#endif
