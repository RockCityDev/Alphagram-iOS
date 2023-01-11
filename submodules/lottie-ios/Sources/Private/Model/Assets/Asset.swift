






import Foundation

public class Asset: Codable, DictionaryInitializable {

  

  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Asset.CodingKeys.self)
    if let id = try? container.decode(String.self, forKey: .id) {
      self.id = id
    } else {
      id = String(try container.decode(Int.self, forKey: .id))
    }
  }

  required init(dictionary: [String: Any]) throws {
    if let id = dictionary[CodingKeys.id.rawValue] as? String {
      self.id = id
    } else if let id = dictionary[CodingKeys.id.rawValue] as? Int {
      self.id = String(id)
    } else {
      throw InitializableError.invalidInput
    }
  }

  

  
  public let id: String

  

  private enum CodingKeys: String, CodingKey {
    case id
  }
}
