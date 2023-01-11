






import Foundation


final class ImageLayerModel: LayerModel {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ImageLayerModel.CodingKeys.self)
    referenceID = try container.decode(String.self, forKey: .referenceID)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    referenceID = try dictionary.value(for: CodingKeys.referenceID)
    try super.init(dictionary: dictionary)
  }

  

  
  let referenceID: String

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(referenceID, forKey: .referenceID)
  }

  

  private enum CodingKeys: String, CodingKey {
    case referenceID = "refId"
  }
}
