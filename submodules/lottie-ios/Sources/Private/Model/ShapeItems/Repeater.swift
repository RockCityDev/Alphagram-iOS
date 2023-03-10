






import Foundation


final class Repeater: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Repeater.CodingKeys.self)
    copies = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .copies) ?? KeyframeGroup(Vector1D(0))
    offset = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .offset) ?? KeyframeGroup(Vector1D(0))
    let transformContainer = try container.nestedContainer(keyedBy: TransformKeys.self, forKey: .transform)
    startOpacity = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .startOpacity) ?? KeyframeGroup(Vector1D(100))
    endOpacity = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .endOpacity) ?? KeyframeGroup(Vector1D(100))
    rotation = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .rotation) ?? KeyframeGroup(Vector1D(0))
    position = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector3D>.self, forKey: .position) ?? KeyframeGroup(Vector3D(x: Double(0), y: 0, z: 0))
    anchorPoint = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector3D>.self, forKey: .anchorPoint) ?? KeyframeGroup(Vector3D(x: Double(0), y: 0, z: 0))
    scale = try transformContainer
      .decodeIfPresent(KeyframeGroup<Vector3D>.self, forKey: .scale) ?? KeyframeGroup(Vector3D(x: Double(100), y: 100, z: 100))
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if let copiesDictionary = dictionary[CodingKeys.copies.rawValue] as? [String: Any] {
      copies = try KeyframeGroup<Vector1D>(dictionary: copiesDictionary)
    } else {
      copies = KeyframeGroup(Vector1D(0))
    }
    if let offsetDictionary = dictionary[CodingKeys.offset.rawValue] as? [String: Any] {
      offset = try KeyframeGroup<Vector1D>(dictionary: offsetDictionary)
    } else {
      offset = KeyframeGroup(Vector1D(0))
    }
    let transformDictionary: [String: Any] = try dictionary.value(for: CodingKeys.transform)
    if let startOpacityDictionary = transformDictionary[TransformKeys.startOpacity.rawValue] as? [String: Any] {
      startOpacity = try KeyframeGroup<Vector1D>(dictionary: startOpacityDictionary)
    } else {
      startOpacity = KeyframeGroup(Vector1D(100))
    }
    if let endOpacityDictionary = transformDictionary[TransformKeys.endOpacity.rawValue] as? [String: Any] {
      endOpacity = try KeyframeGroup<Vector1D>(dictionary: endOpacityDictionary)
    } else {
      endOpacity = KeyframeGroup(Vector1D(100))
    }
    if let rotationDictionary = transformDictionary[TransformKeys.rotation.rawValue] as? [String: Any] {
      rotation = try KeyframeGroup<Vector1D>(dictionary: rotationDictionary)
    } else {
      rotation = KeyframeGroup(Vector1D(0))
    }
    if let positionDictionary = transformDictionary[TransformKeys.position.rawValue] as? [String: Any] {
      position = try KeyframeGroup<Vector3D>(dictionary: positionDictionary)
    } else {
      position = KeyframeGroup(Vector3D(x: Double(0), y: 0, z: 0))
    }
    if let anchorPointDictionary = transformDictionary[TransformKeys.anchorPoint.rawValue] as? [String: Any] {
      anchorPoint = try KeyframeGroup<Vector3D>(dictionary: anchorPointDictionary)
    } else {
      anchorPoint = KeyframeGroup(Vector3D(x: Double(0), y: 0, z: 0))
    }
    if let scaleDictionary = transformDictionary[TransformKeys.scale.rawValue] as? [String: Any] {
      scale = try KeyframeGroup<Vector3D>(dictionary: scaleDictionary)
    } else {
      scale = KeyframeGroup(Vector3D(x: Double(100), y: 100, z: 100))
    }
    try super.init(dictionary: dictionary)
  }

  

  
  let copies: KeyframeGroup<Vector1D>

  
  let offset: KeyframeGroup<Vector1D>

  
  let startOpacity: KeyframeGroup<Vector1D>

  
  let endOpacity: KeyframeGroup<Vector1D>

  
  let rotation: KeyframeGroup<Vector1D>

  
  let anchorPoint: KeyframeGroup<Vector3D>

  
  let position: KeyframeGroup<Vector3D>

  
  let scale: KeyframeGroup<Vector3D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(copies, forKey: .copies)
    try container.encode(offset, forKey: .offset)
    var transformContainer = container.nestedContainer(keyedBy: TransformKeys.self, forKey: .transform)
    try transformContainer.encode(startOpacity, forKey: .startOpacity)
    try transformContainer.encode(endOpacity, forKey: .endOpacity)
    try transformContainer.encode(rotation, forKey: .rotation)
    try transformContainer.encode(position, forKey: .position)
    try transformContainer.encode(anchorPoint, forKey: .anchorPoint)
    try transformContainer.encode(scale, forKey: .scale)
  }

  

  private enum CodingKeys: String, CodingKey {
    case copies = "c"
    case offset = "o"
    case transform = "tr"
  }

  private enum TransformKeys: String, CodingKey {
    case rotation = "r"
    case startOpacity = "so"
    case endOpacity = "eo"
    case anchorPoint = "a"
    case position = "p"
    case scale = "s"
  }
}
