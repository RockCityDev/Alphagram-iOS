






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit

open class AnimatedButton: AnimatedControl {

  

  public override init(
    animation: Animation,
    configuration: LottieConfiguration = .shared)
  {
    super.init(animation: animation, configuration: configuration)
    accessibilityTraits = UIAccessibilityTraits.button
  }

  public override init() {
    super.init()
    accessibilityTraits = UIAccessibilityTraits.button
  }

  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  

  
  public func setPlayRange(fromProgress: AnimationProgressTime, toProgress: AnimationProgressTime, event: UIControl.Event) {
    rangesForEvents[event.rawValue] = (from: fromProgress, to: toProgress)
  }

  
  public func setPlayRange(fromMarker fromName: String, toMarker toName: String, event: UIControl.Event) {
    if
      let start = animationView.progressTime(forMarker: fromName),
      let end = animationView.progressTime(forMarker: toName)
    {
      rangesForEvents[event.rawValue] = (from: start, to: end)
    }
  }

  public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let _ = super.beginTracking(touch, with: event)
    let touchEvent = UIControl.Event.touchDown
    if let playrange = rangesForEvents[touchEvent.rawValue] {
      animationView.play(fromProgress: playrange.from, toProgress: playrange.to, loopMode: LottieLoopMode.playOnce)
    }
    return true
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    let touchEvent: UIControl.Event
    if let touch = touch, bounds.contains(touch.location(in: self)) {
      touchEvent = UIControl.Event.touchUpInside
    } else {
      touchEvent = UIControl.Event.touchUpOutside
    }

    if let playrange = rangesForEvents[touchEvent.rawValue] {
      animationView.play(fromProgress: playrange.from, toProgress: playrange.to, loopMode: LottieLoopMode.playOnce)
    }
  }

  

  fileprivate var rangesForEvents: [UInt : (from: CGFloat, to: CGFloat)] =
    [UIControl.Event.touchUpInside.rawValue : (from: 0, to: 1)]
}
#endif
