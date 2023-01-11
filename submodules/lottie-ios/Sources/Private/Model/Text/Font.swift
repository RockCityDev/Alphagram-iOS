






import Foundation



final class Font: Codable, DictionaryInitializable {

  

  init(dictionary: [String: Any]) throws {
    name = try dictionary.value(for: CodingKeys.name)
    familyName = try dictionary.value(for: CodingKeys.familyName)
    style = try dictionary.value(for: CodingKeys.style)
    ascent = try dictionary.value(for: CodingKeys.ascent)
  }

  

  let name: String
  let familyName: String
  let style: String
  let ascent: Double

  

  private enum CodingKeys: String, CodingKey {
    case name = "fName"
    case familyName = "fFamily"
    case style = "fStyle"
    case ascent
  }

}




final class FontList: Codable, DictionaryInitializable {

  

  init(dictionary: [String: Any]) throws {
    let fontDictionaries: [[String: Any]] = try dictionary.value(for: CodingKeys.fonts)
    fonts = try fontDictionaries.map({ try Font(dictionary: $0) })
  }

  

  enum CodingKeys: String, CodingKey {
    case fonts = "list"
  }

  let fonts: [Font]

}
