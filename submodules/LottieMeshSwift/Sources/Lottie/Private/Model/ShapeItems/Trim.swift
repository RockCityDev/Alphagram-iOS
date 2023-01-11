






import Foundation

enum TrimType: Int, Codable {
  case simultaneously = 1
  case individually = 2
}

final class Trim: ShapeItem {
  
  
  let start: KeyframeGroup<Vector1D>
  
  
  let end: KeyframeGroup<Vector1D>
  
  
  let offset: KeyframeGroup<Vector1D>
  
  let trimType: TrimType
  
  private enum CodingKeys : String, CodingKey {
    case start = "s"
    case end = "e"
    case offset = "o"
    case trimType = "m"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Trim.CodingKeys.self)
    self.start = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .start)
    self.end = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .end)
    self.offset = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .offset)
    self.trimType = try container.decode(TrimType.self, forKey: .trimType)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(start, forKey: .start)
    try container.encode(end, forKey: .end)
    try container.encode(offset, forKey: .offset)
    try container.encode(trimType, forKey: .trimType)
  }
  
}
