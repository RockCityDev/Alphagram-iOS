






import Foundation



enum MergeMode: Int, Codable {
  case none
  case merge
  case add
  case subtract
  case intersect
  case exclude
}




final class Merge: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Merge.CodingKeys.self)
    mode = try container.decode(MergeMode.self, forKey: .mode)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let modeRawType: Int = try dictionary.value(for: CodingKeys.mode)
    guard let mode = MergeMode(rawValue: modeRawType) else {
      throw InitializableError.invalidInput
    }
    self.mode = mode
    try super.init(dictionary: dictionary)
  }

  

  
  let mode: MergeMode

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(mode, forKey: .mode)
  }

  

  private enum CodingKeys: String, CodingKey {
    case mode = "mm"
  }
}
