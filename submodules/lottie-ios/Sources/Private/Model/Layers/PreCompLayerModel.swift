






import Foundation


final class PreCompLayerModel: LayerModel {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: PreCompLayerModel.CodingKeys.self)
    referenceID = try container.decode(String.self, forKey: .referenceID)
    timeRemapping = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .timeRemapping)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    referenceID = try dictionary.value(for: CodingKeys.referenceID)
    if let timeRemappingDictionary = dictionary[CodingKeys.timeRemapping.rawValue] as? [String: Any] {
      timeRemapping = try KeyframeGroup<Vector1D>(dictionary: timeRemappingDictionary)
    } else {
      timeRemapping = nil
    }
    width = try dictionary.value(for: CodingKeys.width)
    height = try dictionary.value(for: CodingKeys.height)
    try super.init(dictionary: dictionary)
  }

  

  
  let referenceID: String

  
  let timeRemapping: KeyframeGroup<Vector1D>?

  
  let width: Double

  
  let height: Double

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(referenceID, forKey: .referenceID)
    try container.encode(timeRemapping, forKey: .timeRemapping)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }

  

  private enum CodingKeys: String, CodingKey {
    case referenceID = "refId"
    case timeRemapping = "tm"
    case width = "w"
    case height = "h"
  }
}
