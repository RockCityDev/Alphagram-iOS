






import Foundation
#if os(iOS) || os(tvOS) || os(watchOS) || targetEnvironment(macCatalyst)
import UIKit





open class AnimatedSwitch: AnimatedControl {

  

  public override init(
    animation: Animation,
    configuration: LottieConfiguration = .shared)
  {
    
    #if os(iOS)
    if #available(iOS 10.0, *) {
      self.hapticGenerator = HapticGenerator()
    } else {
      hapticGenerator = NullHapticGenerator()
    }
    #else
    hapticGenerator = NullHapticGenerator()
    #endif
    super.init(animation: animation, configuration: configuration)
    updateOnState(isOn: _isOn, animated: false, shouldFireHaptics: false)
    accessibilityTraits = UIAccessibilityTraits.button
  }

  public override init() {
    
    #if os(iOS)
    if #available(iOS 10.0, *) {
      self.hapticGenerator = HapticGenerator()
    } else {
      hapticGenerator = NullHapticGenerator()
    }
    #else
    hapticGenerator = NullHapticGenerator()
    #endif
    super.init()
    updateOnState(isOn: _isOn, animated: false, shouldFireHaptics: false)
    accessibilityTraits = UIAccessibilityTraits.button
  }

  required public init?(coder aDecoder: NSCoder) {
    
    #if os(iOS)
    if #available(iOS 10.0, *) {
      self.hapticGenerator = HapticGenerator()
    } else {
      hapticGenerator = NullHapticGenerator()
    }
    #else
    hapticGenerator = NullHapticGenerator()
    #endif
    super.init(coder: aDecoder)
    accessibilityTraits = UIAccessibilityTraits.button
  }

  

  
  
  public enum CancelBehavior {
    case reverse 
    case none 
  }

  
  public var cancelBehavior: CancelBehavior = .reverse

  
  public var isOn: Bool {
    set {
      
      guard _isOn != newValue else { return }
      updateOnState(isOn: newValue, animated: false, shouldFireHaptics: false)
    }
    get {
      _isOn
    }
  }

  
  public func setIsOn(_ isOn: Bool, animated: Bool, shouldFireHaptics: Bool = true) {
    guard isOn != _isOn else { return }
    updateOnState(isOn: isOn, animated: animated, shouldFireHaptics: shouldFireHaptics)
  }

  
  public func setProgressForState(
    fromProgress: AnimationProgressTime,
    toProgress: AnimationProgressTime,
    forOnState: Bool)
  {
    if forOnState {
      onStartProgress = fromProgress
      onEndProgress = toProgress
    } else {
      offStartProgress = fromProgress
      offEndProgress = toProgress
    }

    updateOnState(isOn: _isOn, animated: false, shouldFireHaptics: false)
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    updateOnState(isOn: !_isOn, animated: true, shouldFireHaptics: true)
    sendActions(for: .valueChanged)
  }

  public override func animationDidSet() {
    updateOnState(isOn: _isOn, animated: true, shouldFireHaptics: false)
  }

  

  

  func updateOnState(isOn: Bool, animated: Bool, shouldFireHaptics: Bool) {
    _isOn = isOn
    var startProgress = isOn ? onStartProgress : offStartProgress
    var endProgress = isOn ? onEndProgress : offEndProgress
    let finalProgress = endProgress

    if cancelBehavior == .reverse {
      let realtimeProgress = animationView.realtimeAnimationProgress

      let previousStateStart = isOn ? offStartProgress : onStartProgress
      let previousStateEnd = isOn ? offEndProgress : onEndProgress
      if
        realtimeProgress.isInRange(
          min(previousStateStart, previousStateEnd),
          max(previousStateStart, previousStateEnd))
      {
        
        startProgress = previousStateEnd
        endProgress = previousStateStart
      }
    }

    updateAccessibilityLabel()

    guard animated == true else {
      animationView.currentProgress = finalProgress
      return
    }

    if shouldFireHaptics {
      hapticGenerator.generateImpact()
    }

    animationView.play(
      fromProgress: startProgress,
      toProgress: endProgress,
      loopMode: LottieLoopMode.playOnce,
      completion: { [weak self] finished in
        guard let self = self else { return }

        
        
        if finished, !(self.animationView.animationLayer is CoreAnimationLayer) {
          self.animationView.currentProgress = finalProgress
        }
      })
  }

  

  fileprivate var onStartProgress: CGFloat = 0
  fileprivate var onEndProgress: CGFloat = 1
  fileprivate var offStartProgress: CGFloat = 1
  fileprivate var offEndProgress: CGFloat = 0
  fileprivate var _isOn = false
  fileprivate var hapticGenerator: ImpactGenerator

  

  private func updateAccessibilityLabel() {
    accessibilityValue = _isOn ? NSLocalizedString("On", comment: "On") : NSLocalizedString("Off", comment: "Off")
  }

}
#endif



protocol ImpactGenerator {
  func generateImpact()
}



class NullHapticGenerator: ImpactGenerator {
  func generateImpact() {

  }
}

#if os(iOS)
@available(iOS 10.0, *)
class HapticGenerator: ImpactGenerator {

  

  func generateImpact() {
    impact.impactOccurred()
  }

  

  fileprivate let impact = UIImpactFeedbackGenerator(style: .light)
}
#endif
