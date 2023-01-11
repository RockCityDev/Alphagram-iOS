






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
  
  
  let mode: MergeMode
  
  private enum CodingKeys : String, CodingKey {
    case mode = "mm"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Merge.CodingKeys.self)
    self.mode = try container.decode(MergeMode.self, forKey: .mode)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(mode, forKey: .mode)
  }
  
}
