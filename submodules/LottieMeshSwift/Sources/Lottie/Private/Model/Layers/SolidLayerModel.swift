






import Foundation


final class SolidLayerModel: LayerModel {
  
  
  let colorHex: String
  
  
  let width: Double
  
  
  let height: Double
  
  private enum CodingKeys : String, CodingKey {
    case colorHex = "sc"
    case width = "sw"
    case height = "sh"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: SolidLayerModel.CodingKeys.self)
    self.colorHex = try container.decode(String.self, forKey: .colorHex)
    self.width = try container.decode(Double.self, forKey: .width)
    self.height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(colorHex, forKey: .colorHex)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }
  
}
