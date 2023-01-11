


import Foundation
import QuartzCore




final class CoreAnimationLayer: BaseAnimationLayer {

  

  
  
  
  init(
    animation: Animation,
    imageProvider: AnimationImageProvider,
    fontProvider: AnimationFontProvider,
    compatibilityTrackerMode: CompatibilityTracker.Mode)
    throws
  {
    self.animation = animation
    self.imageProvider = imageProvider
    self.fontProvider = fontProvider
    compatibilityTracker = CompatibilityTracker(mode: compatibilityTrackerMode)
    super.init()

    setup()
    try setupChildLayers()
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("init(layer:) incorrectly called with \(type(of: layer))")
    }

    animation = typedLayer.animation
    currentAnimationConfiguration = typedLayer.currentAnimationConfiguration
    imageProvider = typedLayer.imageProvider
    fontProvider = typedLayer.fontProvider
    didSetUpAnimation = typedLayer.didSetUpAnimation
    compatibilityTracker = typedLayer.compatibilityTracker
    super.init(layer: typedLayer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  
  
  struct CAMediaTimingConfiguration: Equatable {
    var autoreverses = false
    var repeatCount: Float = 0
    var speed: Float = 1
    var timeOffset: TimeInterval = 0
  }

  enum PlaybackState: Equatable {
    
    case playing
    
    case paused(frame: AnimationFrameTime)
  }

  
  
  
  var didSetUpAnimation: (([CompatibilityIssue]) -> Void)?

  
  
  var imageProvider: AnimationImageProvider {
    didSet { reloadImages() }
  }

  
  
  var fontProvider: AnimationFontProvider {
    didSet { reloadFonts() }
  }

  
  
  
  
  
  func playAnimation(
    context: AnimationContext,
    timingConfiguration: CAMediaTimingConfiguration,
    playbackState: PlaybackState = .playing)
  {
    pendingAnimationConfiguration = (
      animationConfiguration: .init(animationContext: context, timingConfiguration: timingConfiguration),
      playbackState: playbackState)

    setNeedsDisplay()
  }

  override func layoutSublayers() {
    super.layoutSublayers()

    
    
    if
      pendingAnimationConfiguration == nil,
      currentAnimationConfiguration == nil,
      bounds.size != .zero
    {
      currentFrame = animation.frameTime(forProgress: animationProgress)
    }
  }

  override func display() {
    
    
    
    
    
    

    if let pendingAnimationConfiguration = pendingAnimationConfiguration {
      self.pendingAnimationConfiguration = nil

      do {
        try setupAnimation(for: pendingAnimationConfiguration.animationConfiguration)
      } catch {
        if case CompatibilityTracker.Error.encounteredCompatibilityIssue(let compatibilityIssue) = error {
          
          
          currentPlaybackState = pendingAnimationConfiguration.playbackState

          didSetUpAnimation?([compatibilityIssue])
          return
        }
      }

      currentPlaybackState = pendingAnimationConfiguration.playbackState

      compatibilityTracker.reportCompatibilityIssues { compatibilityIssues in
        didSetUpAnimation?(compatibilityIssues)
      }
    }
  }

  

  private struct AnimationConfiguration: Equatable {
    let animationContext: AnimationContext
    let timingConfiguration: CAMediaTimingConfiguration
  }

  
  
  private var pendingAnimationConfiguration: (
    animationConfiguration: AnimationConfiguration,
    playbackState: PlaybackState)?

  
  private var currentAnimationConfiguration: AnimationConfiguration?

  
  
  @objc private var animationProgress: CGFloat = 0

  private let animation: Animation
  private let valueProviderStore = ValueProviderStore()
  private let compatibilityTracker: CompatibilityTracker

  
  private var currentPlaybackState: PlaybackState? {
    didSet {
      guard playbackState != oldValue else { return }

      switch playbackState {
      case .playing, nil:
        timeOffset = 0
      case .paused(let frame):
        timeOffset = animation.time(forFrame: frame)
      }
    }
  }

  
  private var playbackState: PlaybackState? {
    pendingAnimationConfiguration?.playbackState ?? currentPlaybackState
  }

  
  private var layerContext: LayerContext {
    LayerContext(
      animation: animation,
      imageProvider: imageProvider,
      fontProvider: fontProvider,
      compatibilityTracker: compatibilityTracker,
      layerName: "root layer")
  }

  private func setup() {
    bounds = animation.bounds
  }

  private func setupChildLayers() throws {
    try setupLayerHierarchy(
      for: animation.layers,
      context: layerContext)
  }

  
  private func setupAnimation(for configuration: AnimationConfiguration) throws {
    
    removeAnimations()

    currentAnimationConfiguration = configuration

    let layerContext = LayerAnimationContext(
      animation: animation,
      timingConfiguration: configuration.timingConfiguration,
      startFrame: configuration.animationContext.playFrom,
      endFrame: configuration.animationContext.playTo,
      valueProviderStore: valueProviderStore,
      compatibilityTracker: compatibilityTracker,
      currentKeypath: AnimationKeypath(keys: []))

    
    
    layoutIfNeeded()

    
    
    
    speed = configuration.timingConfiguration.speed

    
    setupPlaceholderAnimation(context: layerContext)

    
    for animationLayer in sublayers ?? [] {
      try (animationLayer as? AnimationLayer)?.setupAnimations(context: layerContext)
    }
  }

  
  
  
  private func setupPlaceholderAnimation(context: LayerAnimationContext) {
    let animationProgressTracker = CABasicAnimation(keyPath: #keyPath(animationProgress))
    animationProgressTracker.fromValue = 0
    animationProgressTracker.toValue = 1

    let timedProgressAnimation = animationProgressTracker.timed(with: context, for: self)
    timedProgressAnimation.delegate = currentAnimationConfiguration?.animationContext.closure
    add(timedProgressAnimation, forKey: #keyPath(animationProgress))
  }

  
  
  private func rebuildCurrentAnimation() {
    guard
      let currentConfiguration = currentAnimationConfiguration,
      let playbackState = playbackState,
      
      
      
      pendingAnimationConfiguration == nil
    else { return }

    removeAnimations()

    switch playbackState {
    case .paused(let frame):
      currentFrame = frame

    case .playing:
      playAnimation(
        context: currentConfiguration.animationContext,
        timingConfiguration: currentConfiguration.timingConfiguration)
    }
  }

}



extension CoreAnimationLayer: RootAnimationLayer {

  var primaryAnimationKey: AnimationKey {
    .specific(#keyPath(animationProgress))
  }

  var isAnimationPlaying: Bool? {
    switch playbackState {
    case .playing:
      return true
    case nil, .paused:
      return false
    }
  }

  var currentFrame: AnimationFrameTime {
    get {
      switch playbackState {
      case .playing, nil:
        return animation.frameTime(forProgress: (presentation() ?? self).animationProgress)
      case .paused(let frame):
        return frame
      }
    }
    set {
      
      
      
      
      
      let requiredAnimationConfiguration = AnimationConfiguration(
        animationContext: AnimationContext(
          playFrom: animation.startFrame,
          playTo: animation.endFrame,
          closure: nil),
        timingConfiguration: CAMediaTimingConfiguration(speed: 0))

      if
        pendingAnimationConfiguration == nil,
        currentAnimationConfiguration == requiredAnimationConfiguration
      {
        currentPlaybackState = .paused(frame: newValue)
      }

      else {
        playAnimation(
          context: requiredAnimationConfiguration.animationContext,
          timingConfiguration: requiredAnimationConfiguration.timingConfiguration,
          playbackState: .paused(frame: newValue))
      }
    }
  }

  var renderScale: CGFloat {
    get { contentsScale }
    set {
      contentsScale = newValue

      for sublayer in allSublayers {
        sublayer.contentsScale = newValue
      }
    }
  }

  var respectAnimationFrameRate: Bool {
    get { false }
    set { LottieLogger.shared.assertionFailure("`respectAnimationFrameRate` is currently unsupported") }
  }

  var _animationLayers: [CALayer] {
    (sublayers ?? []).filter { $0 is AnimationLayer }
  }

  var textProvider: AnimationTextProvider {
    get { DictionaryTextProvider([:]) }
    set { LottieLogger.shared.assertionFailure("`textProvider` is currently unsupported") }
  }

  func reloadImages() {
    
    
    for sublayer in allSublayers {
      if let imageLayer = sublayer as? ImageLayer {
        imageLayer.setupImage(context: layerContext)
      }
    }
  }

  func reloadFonts() {
    
    
    for sublayer in allSublayers {
      if let textLayer = sublayer as? TextLayer {
        try? textLayer.configureRenderLayer(with: layerContext)
      }
    }
  }

  func forceDisplayUpdate() {
    
  }

  func logHierarchyKeypaths() {
    
  }
    
  func allKeypaths(predicate: (AnimationKeypath) -> Bool) -> [String] {
    return []
  }

  func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    valueProviderStore.setValueProvider(valueProvider, keypath: keypath)

    
    
    rebuildCurrentAnimation()
  }

  func getValue(for _: AnimationKeypath, atFrame _: AnimationFrameTime?) -> Any? {
    LottieLogger.shared.assertionFailure("""
      The Core Animation rendering engine doesn't support querying values for individual frames
      """)
    return nil
  }

  func getOriginalValue(for _: AnimationKeypath, atFrame _: AnimationFrameTime?) -> Any? {
    LottieLogger.shared.assertionFailure("""
      The Core Animation rendering engine doesn't support querying values for individual frames
      """)
    return nil
  }

  func layer(for _: AnimationKeypath) -> CALayer? {
    LottieLogger.shared.assertionFailure("`AnimationKeypath`s are currently unsupported")
    return nil
  }
    
    func allLayers(for keypath: AnimationKeypath) -> [CALayer] {
        LottieLogger.shared.assertionFailure("`AnimationKeypath`s are currently unsupported")
        return []
    }

  func animatorNodes(for _: AnimationKeypath) -> [AnimatorNode]? {
    LottieLogger.shared.assertionFailure("`AnimatorNode`s are not used in this rendering implementation")
    return nil
  }

  func removeAnimations() {
    currentAnimationConfiguration = nil
    currentPlaybackState = nil
    removeAllAnimations()

    for sublayer in allSublayers {
      sublayer.removeAllAnimations()
    }
  }

}



extension CALayer {
  
  @nonobjc
  var allSublayers: [CALayer] {
    var allSublayers: [CALayer] = []

    for sublayer in sublayers ?? [] {
      allSublayers.append(sublayer)
      allSublayers.append(contentsOf: sublayer.allSublayers)
    }

    return allSublayers
  }
}
