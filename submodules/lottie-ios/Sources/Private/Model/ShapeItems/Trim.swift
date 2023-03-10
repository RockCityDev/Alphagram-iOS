






import Foundation



enum TrimType: Int, Codable {
  case simultaneously = 1
  case individually = 2
}




final class Trim: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Trim.CodingKeys.self)
    start = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .start)
    end = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .end)
    offset = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .offset)
    trimType = try container.decode(TrimType.self, forKey: .trimType)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let startDictionary: [String: Any] = try dictionary.value(for: CodingKeys.start)
    start = try KeyframeGroup<Vector1D>(dictionary: startDictionary)
    let endDictionary: [String: Any] = try dictionary.value(for: CodingKeys.end)
    end = try KeyframeGroup<Vector1D>(dictionary: endDictionary)
    let offsetDictionary: [String: Any] = try dictionary.value(for: CodingKeys.offset)
    offset = try KeyframeGroup<Vector1D>(dictionary: offsetDictionary)
    let trimTypeRawValue: Int = try dictionary.value(for: CodingKeys.trimType)
    guard let trimType = TrimType(rawValue: trimTypeRawValue) else {
      throw InitializableError.invalidInput
    }
    self.trimType = trimType
    try super.init(dictionary: dictionary)
  }

  

  
  let start: KeyframeGroup<Vector1D>

  
  let end: KeyframeGroup<Vector1D>

  
  let offset: KeyframeGroup<Vector1D>

  let trimType: TrimType

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(start, forKey: .start)
    try container.encode(end, forKey: .end)
    try container.encode(offset, forKey: .offset)
    try container.encode(trimType, forKey: .trimType)
  }

  

  private enum CodingKeys: String, CodingKey {
    case start = "s"
    case end = "e"
    case offset = "o"
    case trimType = "m"
  }
}
