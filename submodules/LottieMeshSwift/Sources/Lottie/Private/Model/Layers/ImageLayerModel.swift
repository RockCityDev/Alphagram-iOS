






import Foundation


final class ImageLayerModel: LayerModel {
  
  
  let referenceID: String
  
  private enum CodingKeys : String, CodingKey {
    case referenceID = "refId"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ImageLayerModel.CodingKeys.self)
    self.referenceID = try container.decode(String.self, forKey: .referenceID)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(referenceID, forKey: .referenceID)
  }
  
}
