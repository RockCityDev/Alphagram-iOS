






import Foundation
import QuartzCore

final class PreCompositionLayer: CompositionLayer {

  

  init(
    precomp: PreCompLayerModel,
    asset: PrecompAsset,
    layerImageProvider: LayerImageProvider,
    textProvider: AnimationTextProvider,
    fontProvider: AnimationFontProvider,
    assetLibrary: AssetLibrary?,
    frameRate: CGFloat)
  {
    animationLayers = []
    if let keyframes = precomp.timeRemapping?.keyframes {
      remappingNode = NodeProperty(provider: KeyframeInterpolator(keyframes: keyframes))
    } else {
      remappingNode = nil
    }
    self.frameRate = frameRate
    super.init(layer: precomp, size: CGSize(width: precomp.width, height: precomp.height))
    bounds = CGRect(origin: .zero, size: CGSize(width: precomp.width, height: precomp.height))
    contentsLayer.masksToBounds = true
    contentsLayer.bounds = bounds

    let layers = asset.layers.initializeCompositionLayers(
      assetLibrary: assetLibrary,
      layerImageProvider: layerImageProvider,
      textProvider: textProvider,
      fontProvider: fontProvider,
      frameRate: frameRate)

    var imageLayers = [ImageCompositionLayer]()

    var mattedLayer: CompositionLayer? = nil

    for layer in layers.reversed() {
      layer.bounds = bounds
      animationLayers.append(layer)
      if let imageLayer = layer as? ImageCompositionLayer {
        imageLayers.append(imageLayer)
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
      contentsLayer.addSublayer(layer)
    }

    childKeypaths.append(contentsOf: layers)

    layerImageProvider.addImageLayers(imageLayers)
  }

  override init(layer: Any) {
    
    guard let layer = layer as? PreCompositionLayer else {
      fatalError("init(layer:) Wrong Layer Class")
    }
    frameRate = layer.frameRate
    remappingNode = nil
    animationLayers = []

    super.init(layer: layer)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  

  let frameRate: CGFloat
  let remappingNode: NodeProperty<Vector1D>?

  override var keypathProperties: [String: AnyNodeProperty] {
    guard let remappingNode = remappingNode else {
      return super.keypathProperties
    }
    return ["Time Remap" : remappingNode]
  }

  override func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
    let localFrame: CGFloat
    if let remappingNode = remappingNode {
      remappingNode.update(frame: frame)
      localFrame = remappingNode.value.cgFloatValue * frameRate
    } else {
      localFrame = (frame - startFrame) / timeStretch
    }
    animationLayers.forEach( { $0.displayWithFrame(frame: localFrame, forceUpdates: forceUpdates) })
  }

  override func updateRenderScale() {
    super.updateRenderScale()
    animationLayers.forEach( { $0.renderScale = renderScale } )
  }

  

  fileprivate var animationLayers: [CompositionLayer]
}
