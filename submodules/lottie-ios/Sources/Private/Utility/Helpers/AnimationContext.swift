






import CoreGraphics
import Foundation
import QuartzCore


public typealias LottieCompletionBlock = (Bool) -> Void



struct AnimationContext {

  init(
    playFrom: AnimationFrameTime,
    playTo: AnimationFrameTime,
    closure: LottieCompletionBlock?)
  {
    self.playTo = playTo
    self.playFrom = playFrom
    self.closure = AnimationCompletionDelegate(completionBlock: closure)
  }

  var playFrom: AnimationFrameTime
  var playTo: AnimationFrameTime
  var closure: AnimationCompletionDelegate

}



extension AnimationContext: Equatable {
  
  
  
  static func == (_ lhs: AnimationContext, _ rhs: AnimationContext) -> Bool {
    lhs.playTo == rhs.playTo
      && lhs.playFrom == rhs.playFrom
      && (lhs.closure.completionBlock == nil) == (rhs.closure.completionBlock == nil)
  }
}



enum AnimationContextState {
  case playing
  case cancelled
  case complete
}



class AnimationCompletionDelegate: NSObject, CAAnimationDelegate {

  

  init(completionBlock: LottieCompletionBlock?) {
    self.completionBlock = completionBlock
    super.init()
  }

  

  public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    guard ignoreDelegate == false else { return }
    animationState = flag ? .complete : .cancelled
    if let animationLayer = animationLayer, let key = animationKey {
      animationLayer.removeAnimation(forKey: key)
      if flag {
        animationLayer.currentFrame = (anim as! CABasicAnimation).toValue as! CGFloat
      }
    }
    if let completionBlock = completionBlock {
      completionBlock(flag)
    }
  }

  

  var animationLayer: RootAnimationLayer?
  var animationKey: String?
  var ignoreDelegate = false
  var animationState: AnimationContextState = .playing

  let completionBlock: LottieCompletionBlock?
}
