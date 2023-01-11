






import Foundation
import QuartzCore
import UIKit







final class MainThreadAnimationLayer: CALayer, RootAnimationLayer {

  

  init(
    animation: Animation,
    imageProvider: AnimationImageProvider,
    textProvider: AnimationTextProvider,
    fontProvider: AnimationFontProvider)
  {
    layerImageProvider = LayerImageProvider(imageProvider: imageProvider, assets: animation.assetLibrary?.imageAssets)
    layerTextProvider = LayerTextProvider(textProvider: textProvider)
    layerFontProvider = LayerFontProvider(fontProvider: fontProvider)
    animationLayers = []
    super.init()
    bounds = animation.bounds
    let layers = animation.layers.initializeCompositionLayers(
      assetLibrary: animation.assetLibrary,
      layerImageProvider: layerImageProvider,
      textProvider: textProvider,
      fontProvider: fontProvider,
      frameRate: CGFloat(animation.framerate))

    var imageLayers = [ImageCompositionLayer]()
    var textLayers = [TextCompositionLayer]()

    var mattedLayer: CompositionLayer? = nil

    for layer in layers.reversed() {
      layer.bounds = bounds
      animationLayers.append(layer)
      if let imageLayer = layer as? ImageCompositionLayer {
        imageLayers.append(imageLayer)
      }
      if let textLayer = layer as? TextCompositionLayer {
        textLayers.append(textLayer)
      }
      if let matte = mattedLayer {
        
        matte.matteLayer = layer
        mattedLayer = nil
        continue
      }
      if
        let matte = layer.matteType,
        matte == .add || matte == .invert
      {
        
        mattedLayer = layer
      }
      addSublayer(layer)
    }

    layerImageProvider.addImageLayers(imageLayers)
    layerImageProvider.reloadImages()
    layerTextProvider.addTextLayers(textLayers)
    layerTextProvider.reloadTexts()
    layerFontProvider.addTextLayers(textLayers)
    layerFontProvider.reloadTexts()
    setNeedsDisplay()
  }

  
  public override init(layer: Any) {
    animationLayers = []
    layerImageProvider = LayerImageProvider(imageProvider: BlankImageProvider(), assets: nil)
    layerTextProvider = LayerTextProvider(textProvider: DefaultTextProvider())
    layerFontProvider = LayerFontProvider(fontProvider: DefaultFontProvider())
    super.init(layer: layer)

    guard let animationLayer = layer as? MainThreadAnimationLayer else { return }

    currentFrame = animationLayer.currentFrame

  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  public var respectAnimationFrameRate = false

  

  override public class func needsDisplay(forKey key: String) -> Bool {
    if key == "currentFrame" {
      return true
    }
    return super.needsDisplay(forKey: key)
  }

  override public func action(forKey event: String) -> CAAction? {
    if event == "currentFrame" {
      let animation = CABasicAnimation(keyPath: event)
      animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
      animation.fromValue = presentation()?.currentFrame
      if #available(iOS 15.0, *) {
        let maxFps = Float(UIScreen.main.maximumFramesPerSecond)
        if maxFps > 61.0 {
          animation.preferredFrameRateRange = CAFrameRateRange(minimum: maxFps, maximum: maxFps, preferred: maxFps)
        }
      }
      return animation
    }
    return super.action(forKey: event)
  }

  public override func display() {
    guard Thread.isMainThread else { return }
    var newFrame: CGFloat
    if
      let animationKeys = animationKeys(),
      !animationKeys.isEmpty
    {
      newFrame = presentation()?.currentFrame ?? currentFrame
    } else {
      
      newFrame = currentFrame
    }
    if respectAnimationFrameRate {
      newFrame = floor(newFrame)
    }
    animationLayers.forEach { $0.displayWithFrame(frame: newFrame, forceUpdates: false) }
  }

  

  
  @NSManaged var currentFrame: CGFloat

  var animationLayers: ContiguousArray<CompositionLayer>

  var primaryAnimationKey: AnimationKey {
    .managed
  }

  var isAnimationPlaying: Bool? {
    nil 
  }

  var _animationLayers: [CALayer] {
    Array(animationLayers)
  }

  var imageProvider: AnimationImageProvider {
    get {
      layerImageProvider.imageProvider
    }
    set {
      layerImageProvider.imageProvider = newValue
    }
  }

  var renderScale: CGFloat = 1 {
    didSet {
      animationLayers.forEach({ $0.renderScale = renderScale })
    }
  }

  var textProvider: AnimationTextProvider {
    get { layerTextProvider.textProvider }
    set { layerTextProvider.textProvider = newValue }
  }

  var fontProvider: AnimationFontProvider {
    get { layerFontProvider.fontProvider }
    set { layerFontProvider.fontProvider = newValue }
  }

  func reloadImages() {
    layerImageProvider.reloadImages()
  }

  func removeAnimations() {
    
  }

  
  func forceDisplayUpdate() {
    animationLayers.forEach( { $0.displayWithFrame(frame: currentFrame, forceUpdates: true) })
  }

  func logHierarchyKeypaths() {
    print("Lottie: Logging Animation Keypaths")
    animationLayers.forEach({ $0.logKeypaths(for: nil) })
  }
    
  func allKeypaths(predicate: (AnimationKeypath) -> Bool) -> [String] {
    var result: [String] = []
    for animationLayer in animationLayers {
        result.append(contentsOf: animationLayer.allKeypaths(for: nil, predicate: predicate))
    }
    return result
  }

  func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    for layer in animationLayers {
      if let foundProperties = layer.nodeProperties(for: keypath) {
        for property in foundProperties {
          property.setProvider(provider: valueProvider)
        }
        layer.displayWithFrame(frame: presentation()?.currentFrame ?? currentFrame, forceUpdates: true)
      }
    }
  }

  func getValue(for keypath: AnimationKeypath, atFrame: CGFloat?) -> Any? {
    for layer in animationLayers {
      if
        let foundProperties = layer.nodeProperties(for: keypath),
        let first = foundProperties.first
      {
        return first.valueProvider.value(frame: atFrame ?? currentFrame)
      }
    }
    return nil
  }

  func getOriginalValue(for keypath: AnimationKeypath, atFrame: AnimationFrameTime?) -> Any? {
    for layer in animationLayers {
      if
        let foundProperties = layer.nodeProperties(for: keypath),
        let first = foundProperties.first
      {
        return first.originalValueProvider.value(frame: atFrame ?? currentFrame)
      }
    }
    return nil
  }

  func layer(for keypath: AnimationKeypath) -> CALayer? {
    for layer in animationLayers {
      if let foundLayer = layer.layer(for: keypath) {
        return foundLayer
      }
    }
    return nil
  }
    
    func allLayers(for keypath: AnimationKeypath) -> [CALayer] {
        var result: [CALayer] = []
        for layer in animationLayers {
            result.append(contentsOf: layer.allLayers(for: keypath))
        }
        return result
    }

  func animatorNodes(for keypath: AnimationKeypath) -> [AnimatorNode]? {
    var results = [AnimatorNode]()
    for layer in animationLayers {
      if let nodes = layer.animatorNodes(for: keypath) {
        results.append(contentsOf: nodes)
      }
    }
    if results.count == 0 {
      return nil
    }
    return results
  }

  

  fileprivate let layerImageProvider: LayerImageProvider
  fileprivate let layerTextProvider: LayerTextProvider
  fileprivate let layerFontProvider: LayerFontProvider
}



private class BlankImageProvider: AnimationImageProvider {
  func imageForAsset(asset _: ImageAsset) -> CGImage? {
    nil
  }
}
