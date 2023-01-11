


import QuartzCore




final class ShapeLayer: BaseCompositionLayer {

  

  init(shapeLayer: ShapeLayerModel, context: LayerContext) throws {
    self.shapeLayer = shapeLayer
    super.init(layerModel: shapeLayer)
    try setupGroups(from: shapeLayer.items, parentGroup: nil, context: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    shapeLayer = typedLayer.shapeLayer
    super.init(layer: typedLayer)
  }

  

  private let shapeLayer: ShapeLayerModel

}




final class GroupLayer: BaseAnimationLayer {

  

  init(group: Group, inheritedItems: [ShapeItemLayer.Item], context: LayerContext) throws {
    self.group = group
    self.inheritedItems = inheritedItems
    super.init()
    try setupLayerHierarchy(context: context)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  
  
  override init(layer: Any) {
    guard let typedLayer = layer as? Self else {
      fatalError("\(Self.self).init(layer:) incorrectly called with \(type(of: layer))")
    }

    group = typedLayer.group
    inheritedItems = typedLayer.inheritedItems
    super.init(layer: typedLayer)
  }

  

  override func setupAnimations(context: LayerAnimationContext) throws {
    try super.setupAnimations(context: context)

    if let (shapeTransform, context) = nonGroupItems.first(ShapeTransform.self, context: context) {
      try addTransformAnimations(for: shapeTransform, context: context)
      try addOpacityAnimation(for: shapeTransform, context: context)
    }
  }

  

  private let group: Group

  
  
  private let inheritedItems: [ShapeItemLayer.Item]

  
  private lazy var nonGroupItems = group.items
    .filter { !($0 is Group) }
    .map { ShapeItemLayer.Item(item: $0, parentGroup: group) }
    + inheritedItems

  private func setupLayerHierarchy(context: LayerContext) throws {
    
    
    try setupGroups(from: group.items, parentGroup: group, context: context)

    
    
    for shapeRenderGroup in nonGroupItems.shapeRenderGroups.reversed() {
      
      
      
      
      
      
      
      
      if
        shapeRenderGroup.pathItems.count > 1,
        let combinedShapeKeyframes = Keyframes.combinedIfPossible(
          shapeRenderGroup.pathItems.map { ($0.item as? Shape)?.path }),
        
        
        !shapeRenderGroup.otherItems.contains(where: { $0.item is Trim })
      {
        let combinedShape = CombinedShapeItem(
          shapes: combinedShapeKeyframes,
          name: group.name)

        let sublayer = try ShapeItemLayer(
          shape: ShapeItemLayer.Item(item: combinedShape, parentGroup: group),
          otherItems: shapeRenderGroup.otherItems,
          context: context)

        addSublayer(sublayer)
      }

      
      
      else {
        for pathDrawingItem in shapeRenderGroup.pathItems {
          let sublayer = try ShapeItemLayer(
            shape: pathDrawingItem,
            otherItems: shapeRenderGroup.otherItems,
            context: context)

          addSublayer(sublayer)
        }
      }
    }
  }

}

extension CALayer {
  
  
  
  fileprivate func setupGroups(from items: [ShapeItem], parentGroup: Group?, context: LayerContext) throws {
    let (groupItems, otherItems) = items.grouped(by: { $0 is Group })

    
    
    let groupsInZAxisOrder = groupItems.reversed()

    for group in groupsInZAxisOrder {
      guard let group = group as? Group else { continue }

      
      
      
      let inheritedItems: [ShapeItemLayer.Item]
      if !otherItems.contains(where: { $0.drawsCGPath }) {
        inheritedItems = otherItems.map {
          ShapeItemLayer.Item(item: $0, parentGroup: parentGroup)
        }
      } else {
        inheritedItems = []
      }

      let groupLayer = try GroupLayer(
        group: group,
        inheritedItems: inheritedItems,
        context: context)

      addSublayer(groupLayer)
    }
  }
}

extension ShapeItem {
  
  var drawsCGPath: Bool {
    switch type {
    case .ellipse, .rectangle, .shape, .star:
      return true

    case .fill, .gradientFill, .group, .gradientStroke, .merge,
         .repeater, .round, .stroke, .trim, .transform, .unknown:
      return false
    }
  }

  
  var isFill: Bool {
    switch type {
    case .fill, .gradientFill:
      return true

    case .ellipse, .rectangle, .shape, .star, .group, .gradientStroke,
         .merge, .repeater, .round, .stroke, .trim, .transform, .unknown:
      return false
    }
  }

  
  var isStroke: Bool {
    switch type {
    case .stroke, .gradientStroke:
      return true

    case .ellipse, .rectangle, .shape, .star, .group, .gradientFill,
         .merge, .repeater, .round, .fill, .trim, .transform, .unknown:
      return false
    }
  }
}

extension Collection {
  
  func grouped(by predicate: (Element) -> Bool) -> (trueElements: [Element], falseElements: [Element]) {
    var trueElements = [Element]()
    var falseElements = [Element]()

    for element in self {
      if predicate(element) {
        trueElements.append(element)
      } else {
        falseElements.append(element)
      }
    }

    return (trueElements, falseElements)
  }
}




struct ShapeRenderGroup {
  
  var pathItems: [ShapeItemLayer.Item] = []
  
  var otherItems: [ShapeItemLayer.Item] = []
}

extension Array where Element == ShapeItemLayer.Item {
  
  var shapeRenderGroups: [ShapeRenderGroup] {
    var renderGroups = [ShapeRenderGroup()]

    for item in self {
      
      let lastIndex = renderGroups.indices.last!

      if item.item.drawsCGPath {
        renderGroups[lastIndex].pathItems.append(item)
      }

      
      
      
      
      else if item.item.isFill {
        renderGroups[lastIndex].otherItems.append(item)
        renderGroups.append(ShapeRenderGroup())
      }

      
      else {
        for index in renderGroups.indices {
          renderGroups[index].otherItems.append(item)
        }
      }
    }

    
    
    
    return renderGroups.flatMap { group -> [ShapeRenderGroup] in
      let (strokesAndFills, otherItems) = group.otherItems.grouped(by: { $0.item.isFill || $0.item.isStroke })

      
      
      let allAlphaAnimationsAreIdentical = strokesAndFills.allSatisfy { item in
        (item.item as? OpacityAnimationModel)?.opacity
          == (strokesAndFills.first?.item as? OpacityAnimationModel)?.opacity
      }

      if allAlphaAnimationsAreIdentical {
        return [group]
      }

      
      return strokesAndFills.map { strokeOrFill in
        ShapeRenderGroup(
          pathItems: group.pathItems,
          otherItems: [strokeOrFill] + otherItems)
      }
    }
  }
}
