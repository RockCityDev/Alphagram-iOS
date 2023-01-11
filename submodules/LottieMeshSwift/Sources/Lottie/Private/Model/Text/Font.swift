






import Foundation

final class Font: Codable {
  
  let name: String
  let familyName: String
  let style: String
  let ascent: Double
  
  private enum CodingKeys: String, CodingKey {
    case name = "fName"
    case familyName = "fFamily"
    case style = "fStyle"
    case ascent = "ascent"
  }
  
}


final class FontList: Codable {
  
  let fonts: [Font]
  
  enum CodingKeys : String, CodingKey {
    case fonts = "list"
  }
  
}
