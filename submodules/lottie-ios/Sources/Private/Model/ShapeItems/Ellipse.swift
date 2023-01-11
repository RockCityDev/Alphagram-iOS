






import Foundation



enum PathDirection: Int, Codable {
  case clockwise = 1
  case userSetClockwise = 2
  case counterClockwise = 3
}




final class Ellipse: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Ellipse.CodingKeys.self)
    direction = try container.decodeIfPresent(PathDirection.self, forKey: .direction) ?? .clockwise
    position = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .position)
    size = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .size)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    if
      let directionRawType = dictionary[CodingKeys.direction.rawValue] as? Int,
      let direction = PathDirection(rawValue: directionRawType)
    {
      self.direction = direction
    } else {
      direction = .clockwise
    }
    let positionDictionary: [String: Any] = try dictionary.value(for: CodingKeys.position)
    position = try KeyframeGroup<Vector3D>(dictionary: positionDictionary)
    let sizeDictionary: [String: Any] = try dictionary.value(for: CodingKeys.size)
    size = try KeyframeGroup<Vector3D>(dictionary: sizeDictionary)
    try super.init(dictionary: dictionary)
  }

  

  
  let direction: PathDirection

  
  let position: KeyframeGroup<Vector3D>

  
  let size: KeyframeGroup<Vector3D>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(direction, forKey: .direction)
    try container.encode(position, forKey: .position)
    try container.encode(size, forKey: .size)
  }

  

  private enum CodingKeys: String, CodingKey {
    case direction = "d"
    case position = "p"
    case size = "s"
  }
}
