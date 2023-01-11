






import Foundation


final class SolidLayerModel: LayerModel {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: SolidLayerModel.CodingKeys.self)
    colorHex = try container.decode(String.self, forKey: .colorHex)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    colorHex = try dictionary.value(for: CodingKeys.colorHex)
    width = try dictionary.value(for: CodingKeys.width)
    height = try dictionary.value(for: CodingKeys.height)
    try super.init(dictionary: dictionary)
  }

  

  
  let colorHex: String

  
  let width: Double

  
  let height: Double

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(colorHex, forKey: .colorHex)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }

  

  private enum CodingKeys: String, CodingKey {
    case colorHex = "sc"
    case width = "sw"
    case height = "sh"
  }
}
