






import Foundation

enum StarType: Int, Codable {
  case none
  case star
  case polygon
}


final class Star: ShapeItem {
  
  
  let direction: PathDirection
  
  
  let position: KeyframeGroup<Vector3D>
  
  
  let outerRadius: KeyframeGroup<Vector1D>
  
  
  let outerRoundness: KeyframeGroup<Vector1D>
  
  
  let innerRadius: KeyframeGroup<Vector1D>?
  
  
  let innerRoundness: KeyframeGroup<Vector1D>?
  
  
  let rotation: KeyframeGroup<Vector1D>
  
  
  let points: KeyframeGroup<Vector1D>
  
  
  let starType: StarType
  
  private enum CodingKeys : String, CodingKey {
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
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Star.CodingKeys.self)
    self.direction = try container.decodeIfPresent(PathDirection.self, forKey: .direction) ?? .clockwise
    self.position = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .position)
    self.outerRadius = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .outerRadius)
    self.outerRoundness = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .outerRoundness)
    self.innerRadius = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .innerRadius)
    self.innerRoundness = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .innerRoundness)
    self.rotation = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .rotation)
    self.points = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .points)
    self.starType = try container.decode(StarType.self, forKey: .starType)
    try super.init(from: decoder)
  }
  
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
  
}
