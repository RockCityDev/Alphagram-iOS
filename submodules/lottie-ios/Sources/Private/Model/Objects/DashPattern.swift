






import Foundation



enum DashElementType: String, Codable {
  case offset = "o"
  case dash = "d"
  case gap = "g"
}



final class DashElement: Codable, DictionaryInitializable {

  

  init(dictionary: [String: Any]) throws {
    let typeRawValue: String = try dictionary.value(for: CodingKeys.type)
    guard let type = DashElementType(rawValue: typeRawValue) else {
      throw InitializableError.invalidInput
    }
    self.type = type
    let valueDictionary: [String: Any] = try dictionary.value(for: CodingKeys.value)
    value = try KeyframeGroup<Vector1D>(dictionary: valueDictionary)
  }

  

  enum CodingKeys: String, CodingKey {
    case type = "n"
    case value = "v"
  }

  let type: DashElementType
  let value: KeyframeGroup<Vector1D>

}
