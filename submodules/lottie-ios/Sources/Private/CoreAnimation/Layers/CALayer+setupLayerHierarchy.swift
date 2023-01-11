


import QuartzCore

extension CALayer {
  
  
  @nonobjc
  func setupLayerHierarchy(
    for layers: [LayerModel],
    context: LayerContext)
    throws
  {
    
    
    
    
    let layersInZAxisOrder = layers.reversed()

    let layersByIndex = Dictionary(grouping: layersInZAxisOrder, by: \.index)
      .compactMapValues(\.first)

    
    
    
    
    
    func makeParentTransformLayer(
      childLayerModel: LayerModel,
      childLayer: CALayer,
      name: (LayerModel) -> String)
      -> CALayer
    {
      guard
        let parentIndex = childLayerModel.parent,
        let parentLayerModel = layersByIndex[parentIndex]
      else { return childLayer }

      let parentLayer = TransformLayer(layerModel: parentLayerModel)
      parentLayer.name = name(parentLayerModel)
      parentLayer.addSublayer(childLayer)

      return makeParentTransformLayer(
        childLayerModel: parentLayerModel,
        childLayer: parentLayer,
        name: name)
    }

    
    for (layerModel, maskLayerModel) in try layersInZAxisOrder.pairedLayersAndMasks(context: context) {
      guard let layer = try layerModel.makeAnimationLayer(context: context) else {
        continue
      }

      
      
      let parentTransformLayer = makeParentTransformLayer(
        childLayerModel: layerModel,
        childLayer: layer,
        name: { parentLayerModel in
          "\(layerModel.name) (parent, \(parentLayerModel.name))"
        })

      
      if
        let maskLayerModel = maskLayerModel,
        let maskLayer = try maskLayerModel.makeAnimationLayer(context: context)
      {
        let maskParentTransformLayer = makeParentTransformLayer(
          childLayerModel: maskLayerModel,
          childLayer: maskLayer,
          name: { parentLayerModel in
            "\(maskLayerModel.name) (mask of \(layerModel.name)) (parent, \(parentLayerModel.name))"
          })

        
        
        let maskContainer = BaseAnimationLayer()
        maskContainer.name = "\(layerModel.name) (parent, masked)"
        maskContainer.addSublayer(parentTransformLayer)

        
        
        
        let additionalMaskParent = BaseAnimationLayer()
        additionalMaskParent.addSublayer(maskParentTransformLayer)
        maskContainer.mask = additionalMaskParent

        addSublayer(maskContainer)
      }

      else {
        addSublayer(parentTransformLayer)
      }
    }
  }

}

extension Collection where Element == LayerModel {
  
  
  
  
  fileprivate func pairedLayersAndMasks(context: LayerContext) throws -> [(layer: LayerModel, mask: LayerModel?)] {
    var layersAndMasks = [(layer: LayerModel, mask: LayerModel?)]()
    var unprocessedLayers = reversed()

    while let layer = unprocessedLayers.popLast() {
      
      if
        let matteType = layer.matte,
        matteType != .none,
        let maskLayer = unprocessedLayers.popLast()
      {
        try context.compatibilityAssert(
          matteType == .add,
          "The Core Animation rendering engine currently only supports `MatteMode.add`.")

        layersAndMasks.append((layer: layer, mask: maskLayer))
      }

      else {
        layersAndMasks.append((layer: layer, mask: nil))
      }
    }

    return layersAndMasks
  }
}
