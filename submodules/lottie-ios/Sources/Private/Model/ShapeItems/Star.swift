






import Foundation



enum StarType: Int, Codable {
  case none
  case star
  case polygon
}




final class Star: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Star.CodingKeys.self)
    direction = try container.decodeIfPresent(PathDirection.self, forKey: .direction) ?? .clockwise
    position = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .position)
    outerRadius = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .outerRadius)
    outerRoundness = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .outerRoundness)
    innerRadius = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .innerRadius)
    innerRoundness = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .innerRoundness)
    rotation = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .rotation)
    points = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .points)
    starType = try container.decode(StarType.self, forKey: .starType)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if
      let directionRawValue = dictionary[CodingKeys.direction.rawValue] as? Int,
      let direction = PathDirection(rawValue: directionRawValue)
    {
      self.direction = direction
    } else {
      direction = .clockwise
    }
    let positionDictionary: [String: Any] = try dictionary.value(for: CodingKeys.position)
    position = try KeyframeGroup<Vector3D>(dictionary: positionDictionary)
    let outerRadiusDictionary: [String: Any] = try dictionary.value(for: CodingKeys.outerRadius)
    outerRadius = try KeyframeGroup<Vector1D>(dictionary: outerRadiusDictionary)
    let outerRoundnessDictionary: [String: Any] = try dictionary.value(for: CodingKeys.outerRoundness)
    outerRoundness = try KeyframeGroup<Vector1D>(dictionary: outerRoundnessDictionary)
    if let innerRadiusDictionary = dictionary[CodingKeys.innerRadius.rawValue] as? [String: Any] {
      innerRadius = try KeyframeGroup<Vector1D>(dictionary: innerRadiusDictionary)
    } else {
      innerRadius = nil
    }
    if let innerRoundnessDictionary = dictionary[CodingKeys.innerRoundness.rawValue] as? [String: Any] {
      innerRoundness = try KeyframeGroup<Vector1D>(dictionary: innerRoundnessDictionary)
    } else {
      innerRoundness = nil
    }
    let rotationDictionary: [String: Any] = try dictionary.value(for: CodingKeys.rotation)
    rotation = try KeyframeGroup<Vector1D>(dictionary: rotationDictionary)
    let pointsDictionary: [String: Any] = try dictionary.value(for: CodingKeys.points)
    points = try KeyframeGroup<Vector1D>(dictionary: pointsDictionary)
    let starTypeRawValue: Int = try dictionary.value(for: CodingKeys.starType)
    guard let starType = StarType(rawValue: starTypeRawValue) else {
      throw InitializableError.invalidInput
    }
    self.starType = starType
    try super.init(dictionary: dictionary)
  }

  

  
  let direction: PathDirection

  
  let position: KeyframeGroup<Vector3D>

  
  let outerRadius: KeyframeGroup<Vector1D>

  
  let outerRoundness: KeyframeGroup<Vector1D>

  
  let innerRadius: KeyframeGroup<Vector1D>?

  
  let innerRoundness: KeyframeGroup<Vector1D>?

  
  let rotation: KeyframeGroup<Vector1D>

  
  let points: KeyframeGroup<Vector1D>

  
  let starType: StarType

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(position, forKey: .position)
    try container.encode(outerRadius, forKey: .outerRadius)
    try container.encode(outerRoundness, forKey: .outerRoundness)
    try container.encode(innerRadius, forKey: .innerRadius)
    try container.encode(innerRoundness, forKey: .innerRoundness)
    try container.encode(rotation, forKey: .rotation)
    try container.encode(points, forKey: .points)
    try container.encode(starType, forKey: .starType)
  }

  

  private enum CodingKeys: String, CodingKey {
    case direction = "d"
    case position = "p"
    case outerRadius = "or"
    case outerRoundness = "os"
    case innerRadius = "ir"
    case innerRoundness = "is"
    case rotation = "r"
    case points = "pt"
    case starType = "sy"
  }
}
