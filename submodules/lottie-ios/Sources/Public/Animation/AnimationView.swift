






import Foundation
import QuartzCore
import UIKit




public enum LottieBackgroundBehavior {
  
  case stop

  
  
  case pause

  
  case pauseAndRestore

  
  case forceFinish

  
  
  
  
  
  
  case continuePlaying

  

  
  
  
  
  
  public static func `default`(for renderingEngine: RenderingEngine) -> LottieBackgroundBehavior {
    switch renderingEngine {
    case .mainThread:
      return .pause
    case .coreAnimation:
      return .continuePlaying
    }
  }
}




public enum LottieLoopMode {
  
  case playOnce
  
  case loop
  
  case autoReverse
  
  case `repeat`(Float)
  
  case repeatBackwards(Float)
}



extension LottieLoopMode: Equatable {
  public static func == (lhs: LottieLoopMode, rhs: LottieLoopMode) -> Bool {
    switch (lhs, rhs) {
    case (.repeat(let lhsAmount), .repeat(let rhsAmount)),
         (.repeatBackwards(let lhsAmount), .repeatBackwards(let rhsAmount)):
      return lhsAmount == rhsAmount
    case (.playOnce, .playOnce),
         (.loop, .loop),
         (.autoReverse, .autoReverse):
      return true
    default:
      return false
    }
  }
}



@IBDesignable
final public class AnimationView: AnimationViewBase {

  

  

  
  public init(
    animation: Animation?,
    imageProvider: AnimationImageProvider? = nil,
    textProvider: AnimationTextProvider = DefaultTextProvider(),
    fontProvider: AnimationFontProvider = DefaultFontProvider(),
    configuration: LottieConfiguration = .shared)
  {
    self.animation = animation
    self.imageProvider = imageProvider ?? BundleImageProvider(bundle: Bundle.main, searchPath: nil)
    self.textProvider = textProvider
    self.fontProvider = fontProvider
    self.configuration = configuration
    super.init(frame: .zero)
    commonInit()
    makeAnimationLayer(usingEngine: configuration.renderingEngine)
    if let animation = animation {
      frame = animation.bounds
    }
  }

  public init(configuration: LottieConfiguration = .shared) {
    animation = nil
    imageProvider = BundleImageProvider(bundle: Bundle.main, searchPath: nil)
    textProvider = DefaultTextProvider()
    fontProvider = DefaultFontProvider()
    self.configuration = configuration
    super.init(frame: .zero)
    commonInit()
  }

  public override init(frame: CGRect) {
    animation = nil
    imageProvider = BundleImageProvider(bundle: Bundle.main, searchPath: nil)
    textProvider = DefaultTextProvider()
    fontProvider = DefaultFontProvider()
    configuration = .shared
    super.init(frame: frame)
    commonInit()
  }

  required public init?(coder aDecoder: NSCoder) {
    imageProvider = BundleImageProvider(bundle: Bundle.main, searchPath: nil)
    textProvider = DefaultTextProvider()
    fontProvider = DefaultFontProvider()
    configuration = .shared
    super.init(coder: aDecoder)
    commonInit()
  }

  

  
  public let configuration: LottieConfiguration

  
  public private(set) var valueProviders = [AnimationKeypath: AnyValueProvider]()

  
  
  
  
  
  
  
  
  
  
  public var backgroundBehavior: LottieBackgroundBehavior {
    get {
      let currentBackgroundBehavior = _backgroundBehavior ?? .default(for: currentRenderingEngine ?? .mainThread)

      if
        currentRenderingEngine == .mainThread,
        _backgroundBehavior == .continuePlaying
      {
        LottieLogger.shared.assertionFailure("""
          `LottieBackgroundBehavior.continuePlaying` should not be used with the Main Thread
          rendering engine, since this would waste CPU resources on playing an animation
          that is not visible. Consider using a different background mode, or switching to
          the Core Animation rendering engine (which does not have any CPU overhead).
          """)
      }

      return currentBackgroundBehavior
    }
    set {
      _backgroundBehavior = newValue
    }
  }

  
  
  
  public var animation: Animation? {
    didSet {
      makeAnimationLayer(usingEngine: configuration.renderingEngine)
    }
  }

  
  
  
  
  public var imageProvider: AnimationImageProvider {
    didSet {
      animationLayer?.imageProvider = imageProvider.cachedImageProvider
      reloadImages()
    }
  }

  
  
  public var textProvider: AnimationTextProvider {
    didSet {
      animationLayer?.textProvider = textProvider
    }
  }

  
  
  public var fontProvider: AnimationFontProvider {
    didSet {
      animationLayer?.fontProvider = fontProvider
    }
  }

  
  public var isAnimationPlaying: Bool {
    guard let animationLayer = animationLayer else {
      return false
    }

    if let valueFromLayer = animationLayer.isAnimationPlaying {
      return valueFromLayer
    } else {
      return animationLayer.animation(forKey: activeAnimationName) != nil
    }
  }

  
  public var isAnimationQueued: Bool {
    animationContext != nil && waitingToPlayAnimation
  }

  
  public var loopMode: LottieLoopMode = .playOnce {
    didSet {
      updateInFlightAnimation()
    }
  }

  
  
  
  
  
  
  public var shouldRasterizeWhenIdle = false {
    didSet {
      updateRasterizationState()
    }
  }

  
  
  
  
  public var currentProgress: AnimationProgressTime {
    set {
      if let animation = animation {
        currentFrame = animation.frameTime(forProgress: newValue)
      } else {
        currentFrame = 0
      }
    }
    get {
      if let animation = animation {
        return animation.progressTime(forFrame: currentFrame)
      } else {
        return 0
      }
    }
  }

  
  
  
  
  public var currentTime: TimeInterval {
    set {
      if let animation = animation {
        currentFrame = animation.frameTime(forTime: newValue)
      } else {
        currentFrame = 0
      }
    }
    get {
      if let animation = animation {
        return animation.time(forFrame: currentFrame)
      } else {
        return 0
      }
    }
  }

  
  
  
  public var currentFrame: AnimationFrameTime {
    set {
      removeCurrentAnimationIfNecessary()
      updateAnimationFrame(newValue)
    }
    get {
      animationLayer?.currentFrame ?? 0
    }
  }

  
  public var realtimeAnimationFrame: AnimationFrameTime {
    isAnimationPlaying ? animationLayer?.presentation()?.currentFrame ?? currentFrame : currentFrame
  }

  
  public var realtimeAnimationProgress: AnimationProgressTime {
    if let animation = animation {
      return animation.progressTime(forFrame: realtimeAnimationFrame)
    }
    return 0
  }

  
  public var animationSpeed: CGFloat = 1 {
    didSet {
      updateInFlightAnimation()
    }
  }

  
  
  
  
  
  public var respectAnimationFrameRate = false {
    didSet {
      animationLayer?.respectAnimationFrameRate = respectAnimationFrameRate
    }
  }

  
  
  
  
  
  public var viewportFrame: CGRect? = nil {
    didSet {

      
      
      
      
      
      
      
      
      let rect = bounds
      self.bounds = CGRect.zero
      self.bounds = rect
      self.setNeedsLayout()
    }
  }

  override public var intrinsicContentSize: CGSize {
    if let animation = animation {
      return animation.bounds.size
    }
    return .zero
  }

  
  
  
  public var currentRenderingEngine: RenderingEngine? {
    switch configuration.renderingEngine {
    case .specific(let engine):
      return engine

    case .automatic:
      guard let animationLayer = animationLayer else {
        return nil
      }

      if animationLayer is CoreAnimationLayer {
        return .coreAnimation
      } else {
        return .mainThread
      }
    }
  }
    
    private var workaroundDisplayLink: CADisplayLink?
    private var needsWorkaroundDisplayLink: Bool = false {
        didSet {
            if self.needsWorkaroundDisplayLink != oldValue {
                if self.needsWorkaroundDisplayLink {
                    if workaroundDisplayLink == nil {
                        class WorkaroundDisplayLinkTarget {
                            private let f: () -> Void
                            
                            init(_ f: @escaping () -> Void) {
                                self.f = f
                            }
                            
                            @objc func update() {
                                self.f()
                            }
                        }
                        self.workaroundDisplayLink = CADisplayLink(target: WorkaroundDisplayLinkTarget { [weak self] in
                            let _ = self?.realtimeAnimationProgress
                        }, selector: #selector(WorkaroundDisplayLinkTarget.update))
                        if #available(iOS 15.0, *) {
                          let maxFps = Float(UIScreen.main.maximumFramesPerSecond)
                            self.workaroundDisplayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: maxFps, maximum: maxFps, preferred: maxFps)
                        }
                        self.workaroundDisplayLink?.add(to: .main, forMode: .common)
                    }
                } else {
                    if let workaroundDisplayLink = self.workaroundDisplayLink {
                        self.workaroundDisplayLink = nil
                        workaroundDisplayLink.invalidate()
                    }
                }
            }
        }
    }

  
  
  
  public func play(completion: LottieCompletionBlock? = nil) {
    guard let animation = animation else {
      return
    }

    
    let context = AnimationContext(
      playFrom: CGFloat(animation.startFrame),
      playTo: CGFloat(animation.endFrame),
      closure: completion)
    removeCurrentAnimationIfNecessary()
    addNewAnimationForContext(context)
  }

  
  
  
  
  
  
  public func play(
    fromProgress: AnimationProgressTime? = nil,
    toProgress: AnimationProgressTime,
    loopMode: LottieLoopMode? = nil,
    completion: LottieCompletionBlock? = nil)
  {
    guard let animation = animation else {
      return
    }

    removeCurrentAnimationIfNecessary()
    if let loopMode = loopMode {
      
      self.loopMode = loopMode
    }
    let context = AnimationContext(
      playFrom: animation.frameTime(forProgress: fromProgress ?? currentProgress),
      playTo: animation.frameTime(forProgress: toProgress),
      closure: completion)
    addNewAnimationForContext(context)
  }

  
  
  
  
  
  
  public func play(
    fromFrame: AnimationFrameTime? = nil,
    toFrame: AnimationFrameTime,
    loopMode: LottieLoopMode? = nil,
    completion: LottieCompletionBlock? = nil)
  {
    removeCurrentAnimationIfNecessary()
    if let loopMode = loopMode {
      
      self.loopMode = loopMode
    }

    let context = AnimationContext(
      playFrom: fromFrame ?? currentProgress,
      playTo: toFrame,
      closure: completion)
    addNewAnimationForContext(context)
  }

  
  
  
  
  
  
  
  
  
  
  
  
  public func play(
    fromMarker: String? = nil,
    toMarker: String,
    loopMode: LottieLoopMode? = nil,
    completion: LottieCompletionBlock? = nil)
  {

    guard let animation = animation, let markers = animation.markerMap, let to = markers[toMarker] else {
      return
    }

    removeCurrentAnimationIfNecessary()
    if let loopMode = loopMode {
      
      self.loopMode = loopMode
    }

    let fromTime: CGFloat
    if let fromName = fromMarker, let from = markers[fromName] {
      fromTime = CGFloat(from.frameTime)
    } else {
      fromTime = currentFrame
    }

    let context = AnimationContext(
      playFrom: fromTime,
      playTo: CGFloat(to.frameTime),
      closure: completion)
    addNewAnimationForContext(context)
  }

  
  
  
  public func stop() {
    removeCurrentAnimation()
    currentFrame = 0
  }

  
  
  
  public func pause() {
    removeCurrentAnimation()
  }

  
  public func reloadImages() {
    animationLayer?.reloadImages()
  }

  
  public func forceDisplayUpdate() {
    animationLayer?.forceDisplayUpdate()
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  /// let fillKeypath = AnimationKeypath(keypath: "**.Fill 1.Color")
  
  
  
  
  
  public func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    guard let animationLayer = animationLayer else { return }

    valueProviders[keypath] = valueProvider
    animationLayer.setValueProvider(valueProvider, keypath: keypath)
  }

  
  
  
  
  
  public func getValue(for keypath: AnimationKeypath, atFrame: AnimationFrameTime?) -> Any? {
    animationLayer?.getValue(for: keypath, atFrame: atFrame)
  }

  
  
  
  
  
  
  public func getOriginalValue(for keypath: AnimationKeypath, atFrame: AnimationFrameTime?) -> Any? {
    animationLayer?.getOriginalValue(for: keypath, atFrame: atFrame)
  }

  
  public func logHierarchyKeypaths() {
    animationLayer?.logHierarchyKeypaths()
  }
    
  public func allKeypaths(predicate: (AnimationKeypath) -> Bool) -> [String] {
    return animationLayer?.allKeypaths(predicate: predicate) ?? []
  }

  
  
  
  
  
  
  
  
  
  
  
  
  /// let layerKeypath = AnimationKeypath(keypath: "Layer 1")
  
  
  
  
  
  
  
  
  public func addSubview(_ subview: AnimationSubview, forLayerAt keypath: AnimationKeypath) {
    guard let sublayer = animationLayer?.layer(for: keypath) else {
      return
    }
    setNeedsLayout()
    layoutIfNeeded()
    forceDisplayUpdate()
    addSubview(subview)
    if let subViewLayer = subview.viewLayer {
      sublayer.addSublayer(subViewLayer)
    }
  }
    
    public func allLayers(forKeypath keypath: AnimationKeypath) -> [CALayer] {
        return animationLayer?.allLayers(for: keypath) ?? []
    }

  
  
  
  
  
  
  
  public func convert(_ rect: CGRect, toLayerAt keypath: AnimationKeypath?) -> CGRect? {
    guard let animationLayer = animationLayer else { return nil }
    guard let keypath = keypath else {
      return viewLayer?.convert(rect, to: animationLayer)
    }
    guard let sublayer = animationLayer.layer(for: keypath) else {
      return nil
    }
    setNeedsLayout()
    layoutIfNeeded()
    forceDisplayUpdate()
    return animationLayer.convert(rect, to: sublayer)
  }

  
  
  
  
  
  
  
  public func convert(_ point: CGPoint, toLayerAt keypath: AnimationKeypath?) -> CGPoint? {
    guard let animationLayer = animationLayer else { return nil }
    guard let keypath = keypath else {
      return viewLayer?.convert(point, to: animationLayer)
    }
    guard let sublayer = animationLayer.layer(for: keypath) else {
      return nil
    }
    setNeedsLayout()
    layoutIfNeeded()
    forceDisplayUpdate()
    return animationLayer.convert(point, to: sublayer)
  }

  
  
  
  
  
  public func setNodeIsEnabled(isEnabled: Bool, keypath: AnimationKeypath) {
    guard let animationLayer = animationLayer else { return }
    let nodes = animationLayer.animatorNodes(for: keypath)
    if let nodes = nodes {
      for node in nodes {
        node.isEnabled = isEnabled
      }
      forceDisplayUpdate()
    }
  }

  
  
  
  
  
  
  
  
  public func progressTime(forMarker named: String) -> AnimationProgressTime? {
    guard let animation = animation else {
      return nil
    }
    return animation.progressTime(forMarker: named)
  }

  
  
  
  
  
  
  
  
  public func frameTime(forMarker named: String) -> AnimationFrameTime? {
    guard let animation = animation else {
      return nil
    }
    return animation.frameTime(forMarker: named)
  }

  

  var animationLayer: RootAnimationLayer? = nil

  
  @IBInspectable var animationName: String? {
    didSet {
      self.animation = animationName.flatMap {
        Animation.named($0, animationCache: nil)
      }
    }
  }

  override func layoutAnimation() {
    guard let animation = animation, let animationLayer = animationLayer else { return }
    var position = animation.bounds.center
    let xform: CATransform3D
    var shouldForceUpdates = false

    if let viewportFrame = viewportFrame {
      shouldForceUpdates = contentMode == .redraw

      let compAspect = viewportFrame.size.width / viewportFrame.size.height
      let viewAspect = bounds.size.width / bounds.size.height
      let dominantDimension = compAspect > viewAspect ? bounds.size.width : bounds.size.height
      let compDimension = compAspect > viewAspect ? viewportFrame.size.width : viewportFrame.size.height
      let scale = dominantDimension / compDimension

      let viewportOffset = animation.bounds.center - viewportFrame.center
      xform = CATransform3DTranslate(CATransform3DMakeScale(scale, scale, 1), viewportOffset.x, viewportOffset.y, 0)
      position = bounds.center
    } else {
      switch contentMode {
      case .scaleToFill:
        position = bounds.center
        xform = CATransform3DMakeScale(
          bounds.size.width / animation.size.width,
          bounds.size.height / animation.size.height,
          1);
      case .scaleAspectFit:
        position = bounds.center
        let compAspect = animation.size.width / animation.size.height
        let viewAspect = bounds.size.width / bounds.size.height
        let dominantDimension = compAspect > viewAspect ? bounds.size.width : bounds.size.height
        let compDimension = compAspect > viewAspect ? animation.size.width : animation.size.height
        let scale = dominantDimension / compDimension
        xform = CATransform3DMakeScale(scale, scale, 1)
      case .scaleAspectFill:
        position = bounds.center
        let compAspect = animation.size.width / animation.size.height
        let viewAspect = bounds.size.width / bounds.size.height
        let scaleWidth = compAspect < viewAspect
        let dominantDimension = scaleWidth ? bounds.size.width : bounds.size.height
        let compDimension = scaleWidth ? animation.size.width : animation.size.height
        let scale = dominantDimension / compDimension
        xform = CATransform3DMakeScale(scale, scale, 1)
      case .redraw:
        shouldForceUpdates = true
        xform = CATransform3DIdentity
      case .center:
        position = bounds.center
        xform = CATransform3DIdentity
      case .top:
        position.x = bounds.center.x
        xform = CATransform3DIdentity
      case .bottom:
        position.x = bounds.center.x
        position.y = bounds.maxY - animation.bounds.midY
        xform = CATransform3DIdentity
      case .left:
        position.y = bounds.center.y
        xform = CATransform3DIdentity
      case .right:
        position.y = bounds.center.y
        position.x = bounds.maxX - animation.bounds.midX
        xform = CATransform3DIdentity
      case .topLeft:
        xform = CATransform3DIdentity
      case .topRight:
        position.x = bounds.maxX - animation.bounds.midX
        xform = CATransform3DIdentity
      case .bottomLeft:
        position.y = bounds.maxY - animation.bounds.midY
        xform = CATransform3DIdentity
      case .bottomRight:
        position.x = bounds.maxX - animation.bounds.midX
        position.y = bounds.maxY - animation.bounds.midY
        xform = CATransform3DIdentity

      #if os(iOS) || os(tvOS)
      @unknown default:
        LottieLogger.shared.assertionFailure("unsupported contentMode: \(contentMode.rawValue)")
        xform = CATransform3DIdentity
      #endif
      }
    }

    
    
    
    
    
    
    if let key = viewLayer?.animationKeys()?.first, let animation = viewLayer?.animation(forKey: key) {
      

      let positionKey = "LayoutPositionAnimation"
      let transformKey = "LayoutTransformAnimation"
      animationLayer.removeAnimation(forKey: positionKey)
      animationLayer.removeAnimation(forKey: transformKey)

      let positionAnimation = animation.copy() as? CABasicAnimation ?? CABasicAnimation(keyPath: "position")
      positionAnimation.keyPath = "position"
      positionAnimation.isAdditive = false
      positionAnimation.fromValue = (animationLayer.presentation() ?? animationLayer).position
      positionAnimation.toValue = position
      positionAnimation.isRemovedOnCompletion = true

      let xformAnimation = animation.copy() as? CABasicAnimation ?? CABasicAnimation(keyPath: "transform")
      xformAnimation.keyPath = "transform"
      xformAnimation.isAdditive = false
      xformAnimation.fromValue = (animationLayer.presentation() ?? animationLayer).transform
      xformAnimation.toValue = xform
      xformAnimation.isRemovedOnCompletion = true

      animationLayer.position = position
      animationLayer.transform = xform
      #if os(OSX)
      animationLayer.anchorPoint = layer?.anchorPoint ?? CGPoint.zero
      #else
      animationLayer.anchorPoint = layer.anchorPoint
      #endif
      animationLayer.add(positionAnimation, forKey: positionKey)
      animationLayer.add(xformAnimation, forKey: transformKey)
    } else {
      
      
      
      
      
      if TestHelpers.performanceTestsAreRunning {
        animationLayer.position = position
        animationLayer.transform = xform
      } else {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))
        animationLayer.position = position
        animationLayer.transform = xform
        CATransaction.commit()
      }
    }

    if shouldForceUpdates {
      animationLayer.forceDisplayUpdate()
    }
  }

  func updateRasterizationState() {
    if isAnimationPlaying {
      animationLayer?.shouldRasterize = false
    } else {
      animationLayer?.shouldRasterize = shouldRasterizeWhenIdle
    }
  }

  
  func updateAnimationFrame(_ newFrame: CGFloat) {
    
    
    
    
    
    if TestHelpers.performanceTestsAreRunning {
      animationLayer?.currentFrame = newFrame
      animationLayer?.forceDisplayUpdate()
      return
    }

    CATransaction.begin()
    CATransaction.setCompletionBlock {
      self.animationLayer?.forceDisplayUpdate()
    }
    CATransaction.setDisableActions(true)
    animationLayer?.currentFrame = newFrame
    CATransaction.commit()
  }

  @objc
  override func animationWillMoveToBackground() {
    updateAnimationForBackgroundState()
  }

  @objc
  override func animationWillEnterForeground() {
    updateAnimationForForegroundState()
  }

  override func animationMovedToWindow() {
    
    
    guard superview != nil else { return }

    if window != nil {
      updateAnimationForForegroundState()
    } else {
      updateAnimationForBackgroundState()
    }
  }

  

  fileprivate var animationContext: AnimationContext?
  fileprivate var _activeAnimationName: String = AnimationView.animationName
  fileprivate var animationID = 0

  fileprivate var waitingToPlayAnimation = false

  fileprivate var activeAnimationName: String {
    switch animationLayer?.primaryAnimationKey {
    case .specific(let animationKey):
      return animationKey
    case .managed, nil:
      return _activeAnimationName
    }
  }

  fileprivate func makeAnimationLayer(usingEngine renderingEngine: RenderingEngineOption) {

    
    removeCurrentAnimation()

    if let oldAnimation = animationLayer {
      oldAnimation.removeFromSuperlayer()
    }

    invalidateIntrinsicContentSize()

    guard let animation = animation else {
      return
    }

    let rootAnimationLayer: RootAnimationLayer?
    switch renderingEngine {
    case .automatic:
      rootAnimationLayer = makeAutomaticEngineLayer(for: animation)
    case .specific(.coreAnimation):
      rootAnimationLayer = makeCoreAnimationLayer(for: animation)
    case .specific(.mainThread):
      rootAnimationLayer = makeMainThreadAnimationLayer(for: animation)
    }

    guard let animationLayer = rootAnimationLayer else {
      return
    }

    animationLayer.renderScale = screenScale

    viewLayer?.addSublayer(animationLayer)
    self.animationLayer = animationLayer
    reloadImages()
    animationLayer.setNeedsDisplay()
    setNeedsLayout()
    currentFrame = CGFloat(animation.startFrame)
  }

  fileprivate func makeMainThreadAnimationLayer(for animation: Animation) -> MainThreadAnimationLayer {
    MainThreadAnimationLayer(
      animation: animation,
      imageProvider: imageProvider.cachedImageProvider,
      textProvider: textProvider,
      fontProvider: fontProvider)
  }

  fileprivate func makeCoreAnimationLayer(for animation: Animation) -> CoreAnimationLayer? {
    do {
      let coreAnimationLayer = try CoreAnimationLayer(
        animation: animation,
        imageProvider: imageProvider.cachedImageProvider,
        fontProvider: fontProvider,
        compatibilityTrackerMode: .track)

      coreAnimationLayer.didSetUpAnimation = { compatibilityIssues in
        LottieLogger.shared.assert(
          compatibilityIssues.isEmpty,
          "Encountered Core Animation compatibility issues while setting up animation:\n"
            + compatibilityIssues.map { $0.description }.joined(separator: "\n") + "\n\n"
            + """
              This animation cannot be rendered correctly by the Core Animation engine.
              To resolve this issue, you can use `RenderingEngineOption.automatic`, which automatically falls back
              to the Main Thread rendering engine when necessary, or just use `RenderingEngineOption.mainThread`.

              """)
      }

      return coreAnimationLayer
    } catch {
      
      
      
      LottieLogger.shared.assertionFailure("Encountered unexpected error \(error)")
      return nil
    }
  }

  fileprivate func makeAutomaticEngineLayer(for animation: Animation) -> CoreAnimationLayer? {
    do {
      
      
      let coreAnimationLayer = try CoreAnimationLayer(
        animation: animation,
        imageProvider: imageProvider.cachedImageProvider,
        fontProvider: fontProvider,
        compatibilityTrackerMode: .abort)

      coreAnimationLayer.didSetUpAnimation = { [weak self] issues in
        self?.automaticEngineLayerDidSetUpAnimation(issues)
      }

      return coreAnimationLayer
    } catch {
      if case CompatibilityTracker.Error.encounteredCompatibilityIssue(let compatibilityIssue) = error {
        automaticEngineLayerDidSetUpAnimation([compatibilityIssue])
      } else {
        
        
        LottieLogger.shared.assertionFailure("Encountered unexpected error \(error)")
        automaticEngineLayerDidSetUpAnimation([])
      }

      return nil
    }
  }

  
  
  fileprivate func automaticEngineLayerDidSetUpAnimation(_ compatibilityIssues: [CompatibilityIssue]) {
    
    if compatibilityIssues.isEmpty {
      return
    }

    LottieLogger.shared.warn(
      "Encountered Core Animation compatibility issue while setting up animation:\n"
        + compatibilityIssues.map { $0.description }.joined(separator: "\n") + "\n"
        + """
          This animation may have additional compatibility issues, but animation setup was cancelled early to avoid wasted work.

          Automatically falling back to Main Thread rendering engine. This fallback comes with some additional performance
          overhead, which can be reduced by manually specifying that this animation should always use the Main Thread engine.

          """)

    let animationContext = self.animationContext
    let currentFrame = self.currentFrame

    makeAnimationLayer(usingEngine: .mainThread)

    
    
    self.currentFrame = currentFrame

    if let animationContext = animationContext {
      
      
      
      
      addNewAnimationForContext(AnimationContext(
        playFrom: animationContext.playFrom,
        playTo: animationContext.playTo,
        closure: animationContext.closure.completionBlock))
    }
  }

  fileprivate func updateAnimationForBackgroundState() {
    if let currentContext = animationContext {
      switch backgroundBehavior {
      case .stop:
        removeCurrentAnimation()
        updateAnimationFrame(currentContext.playFrom)
      case .pause:
        removeCurrentAnimation()
      case .pauseAndRestore:
        currentContext.closure.ignoreDelegate = true
        removeCurrentAnimation()
        
        animationContext = currentContext
      case .forceFinish:
        removeCurrentAnimation()
        updateAnimationFrame(currentContext.playTo)
      case .continuePlaying:
        break
      }
    }
  }

  fileprivate func updateAnimationForForegroundState() {
    if let currentContext = animationContext {
      if waitingToPlayAnimation {
        waitingToPlayAnimation = false
        addNewAnimationForContext(currentContext)
      } else if backgroundBehavior == .pauseAndRestore {
        
        updateInFlightAnimation()
      }
    }
  }

  
  
  
  
  
  fileprivate func removeCurrentAnimationIfNecessary() {
    switch currentRenderingEngine {
    case .mainThread:
      removeCurrentAnimation()
    case .coreAnimation, nil:
      break
    }
  }

  
  fileprivate func removeCurrentAnimation() {
    guard animationContext != nil else { return }
    let pauseFrame = realtimeAnimationFrame
    animationLayer?.removeAnimation(forKey: activeAnimationName)
    updateAnimationFrame(pauseFrame)
    animationContext = nil
    
    self.needsWorkaroundDisplayLink = false
  }

  
  fileprivate func updateInFlightAnimation() {
    guard let animationContext = animationContext else { return }

    guard animationContext.closure.animationState != .complete else {
      
      self.animationContext = nil
      return
    }

    
    animationContext.closure.ignoreDelegate = true

    
    let newContext = AnimationContext(
      playFrom: animationContext.playFrom,
      playTo: animationContext.playTo,
      closure: animationContext.closure.completionBlock)

    
    let pauseFrame = realtimeAnimationFrame
    animationLayer?.removeAnimation(forKey: activeAnimationName)
    animationLayer?.currentFrame = pauseFrame

    addNewAnimationForContext(newContext)
  }

  
  fileprivate func addNewAnimationForContext(_ animationContext: AnimationContext) {
    guard let animationlayer = animationLayer, let animation = animation else {
      return
    }

    self.animationContext = animationContext

    switch currentRenderingEngine {
    case .mainThread:
      guard window != nil else {
        waitingToPlayAnimation = true
        return
      }

    case .coreAnimation, nil:
      
      
      
      break
    }

    animationID = animationID + 1
    _activeAnimationName = AnimationView.animationName + String(animationID)

    if let coreAnimationLayer = animationlayer as? CoreAnimationLayer {
      var animationContext = animationContext
      var timingConfiguration = CoreAnimationLayer.CAMediaTimingConfiguration(
        autoreverses: loopMode.caAnimationConfiguration.autoreverses,
        repeatCount: loopMode.caAnimationConfiguration.repeatCount,
        speed: Float(animationSpeed))

      
      
      let lowerBoundTime = min(animationContext.playFrom, animationContext.playTo)
      let upperBoundTime = max(animationContext.playFrom, animationContext.playTo)
      if (lowerBoundTime ..< upperBoundTime).contains(round(currentFrame)) {
        
        switch loopMode {
        
        
        
        
        case .playOnce:
          animationContext.playFrom = currentFrame

        
        
        
        
        default:
          timingConfiguration.timeOffset = currentTime - animation.time(forFrame: animationContext.playFrom)
        }
      }

      coreAnimationLayer.playAnimation(
        context: animationContext,
        timingConfiguration: timingConfiguration)

      return
    }

    

    let framerate = animation.framerate

    let playFrom = animationContext.playFrom.clamp(animation.startFrame, animation.endFrame)
    let playTo = animationContext.playTo.clamp(animation.startFrame, animation.endFrame)

    let duration = ((max(playFrom, playTo) - min(playFrom, playTo)) / CGFloat(framerate))

    let playingForward: Bool =
      (
        (animationSpeed > 0 && playFrom < playTo) ||
          (animationSpeed < 0 && playTo < playFrom))

    var startFrame = currentFrame.clamp(min(playFrom, playTo), max(playFrom, playTo))
    if startFrame == playTo {
      startFrame = playFrom
    }

    let timeOffset: TimeInterval = playingForward
      ? Double(startFrame - min(playFrom, playTo)) / framerate
      : Double(max(playFrom, playTo) - startFrame) / framerate

    let layerAnimation = CABasicAnimation(keyPath: "currentFrame")
    layerAnimation.fromValue = playFrom
    layerAnimation.toValue = playTo
    layerAnimation.speed = Float(animationSpeed)
    layerAnimation.duration = TimeInterval(duration)
    layerAnimation.fillMode = CAMediaTimingFillMode.both
    layerAnimation.repeatCount = loopMode.caAnimationConfiguration.repeatCount
    layerAnimation.autoreverses = loopMode.caAnimationConfiguration.autoreverses
    if #available(iOS 15.0, *) {
      let maxFps = Float(UIScreen.main.maximumFramesPerSecond)
      if maxFps > 61.0 {
          layerAnimation.preferredFrameRateRange = CAFrameRateRange(minimum: maxFps, maximum: maxFps, preferred: maxFps)
      }
    }

    layerAnimation.isRemovedOnCompletion = false
    if timeOffset != 0 {
      let currentLayerTime = viewLayer?.convertTime(CACurrentMediaTime(), from: nil) ?? 0
      layerAnimation.beginTime = currentLayerTime - (timeOffset * 1 / Double(abs(animationSpeed)))
    }
    layerAnimation.delegate = animationContext.closure
    animationContext.closure.animationLayer = animationlayer
    animationContext.closure.animationKey = activeAnimationName

    animationlayer.add(layerAnimation, forKey: activeAnimationName)
    self.needsWorkaroundDisplayLink = true
    updateRasterizationState()
  }

  

  static private let animationName = "Lottie"

  
  private var _backgroundBehavior: LottieBackgroundBehavior?

}



extension LottieLoopMode {
  
  var caAnimationConfiguration: (repeatCount: Float, autoreverses: Bool) {
    switch self {
    case .playOnce:
      return (repeatCount: 1, autoreverses: false)
    case .loop:
      return (repeatCount: .greatestFiniteMagnitude, autoreverses: false)
    case .autoReverse:
      return (repeatCount: .greatestFiniteMagnitude, autoreverses: true)
    case .repeat(let amount):
      return (repeatCount: amount, autoreverses: false)
    case .repeatBackwards(let amount):
      return (repeatCount: amount, autoreverses: true)
    }
  }
}
