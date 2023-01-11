


import QuartzCore




protocol RootAnimationLayer: CALayer {
  var currentFrame: AnimationFrameTime { get set }
  var renderScale: CGFloat { get set }
  var respectAnimationFrameRate: Bool { get set }

  var _animationLayers: [CALayer] { get }
  var imageProvider: AnimationImageProvider { get set }
  var textProvider: AnimationTextProvider { get set }
  var fontProvider: AnimationFontProvider { get set }

  
  
  var primaryAnimationKey: AnimationKey { get }

  
  
  
  var isAnimationPlaying: Bool? { get }

  
  
  func removeAnimations()

  func reloadImages()
  func forceDisplayUpdate()
  func logHierarchyKeypaths()
  func allKeypaths(predicate: (AnimationKeypath) -> Bool) -> [String]

  func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath)
  func getValue(for keypath: AnimationKeypath, atFrame: AnimationFrameTime?) -> Any?
  func getOriginalValue(for keypath: AnimationKeypath, atFrame: AnimationFrameTime?) -> Any?

  func layer(for keypath: AnimationKeypath) -> CALayer?
  func allLayers(for keypath: AnimationKeypath) -> [CALayer]
  func animatorNodes(for keypath: AnimationKeypath) -> [AnimatorNode]?
}



enum AnimationKey {
  
  case managed
  
  case specific(String)
}
