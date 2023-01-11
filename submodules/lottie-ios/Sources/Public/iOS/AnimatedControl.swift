






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit
















open class AnimatedControl: UIControl {

  

  

  public init(
    animation: Animation,
    configuration: LottieConfiguration = .shared)
  {
    animationView = AnimationView(
      animation: animation,
      configuration: configuration)

    super.init(frame: animation.bounds)
    commonInit()
  }

  public init() {
    animationView = AnimationView()
    super.init(frame: .zero)
    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    animationView = AnimationView()
    super.init(coder: aDecoder)
    commonInit()
  }

  

  

  open override var isEnabled: Bool {
    didSet {
      updateForState()
    }
  }

  open override var isSelected: Bool {
    didSet {
      updateForState()
    }
  }

  open override var isHighlighted: Bool {
    didSet {
      updateForState()
    }
  }

  open override var intrinsicContentSize: CGSize {
    animationView.intrinsicContentSize
  }

  open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    updateForState()
    return super.beginTracking(touch, with: event)
  }

  open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    updateForState()
    return super.continueTracking(touch, with: event)
  }

  open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    updateForState()
    return super.endTracking(touch, with: event)
  }

  open override func cancelTracking(with event: UIEvent?) {
    updateForState()
    super.cancelTracking(with: event)
  }

  open func animationDidSet() {

  }

  

  
  public let animationView: AnimationView

  
  public var animation: Animation? {
    didSet {
      animationView.animation = animation
      animationView.bounds = animation?.bounds ?? .zero
      setNeedsLayout()
      updateForState()
      animationDidSet()
    }
  }

  
  public var animationSpeed: CGFloat {
    set { animationView.animationSpeed = newValue }
    get { animationView.animationSpeed }
  }

  
  public func setLayer(named: String, forState: UIControl.State) {
    stateMap[forState.rawValue] = named
    updateForState()
  }

  
  public func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    animationView.setValueProvider(valueProvider, keypath: keypath)
  }

  

  var stateMap: [UInt: String] = [:]

  func updateForState() {
    guard let animationLayer = animationView.animationLayer else { return }
    if
      let layerName = stateMap[state.rawValue],
      let stateLayer = animationLayer.layer(for: AnimationKeypath(keypath: layerName))
    {
      for layer in animationLayer._animationLayers {
        layer.isHidden = true
      }
      stateLayer.isHidden = false
    } else {
      for layer in animationLayer._animationLayers {
        layer.isHidden = false
      }
    }
  }

  

  fileprivate func commonInit() {
    animationView.clipsToBounds = false
    clipsToBounds = true
    animationView.translatesAutoresizingMaskIntoConstraints = false
    animationView.backgroundBehavior = .forceFinish
    addSubview(animationView)
    animationView.contentMode = .scaleAspectFit
    animationView.isUserInteractionEnabled = false
    animationView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    animationView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    animationView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    animationView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
  }
}
#endif
