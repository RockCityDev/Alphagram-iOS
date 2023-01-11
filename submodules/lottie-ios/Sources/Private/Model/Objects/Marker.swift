






import Foundation


final class Marker: Codable, DictionaryInitializable {

  

  init(dictionary: [String: Any]) throws {
    name = try dictionary.value(for: CodingKeys.name)
    frameTime = try dictionary.value(for: CodingKeys.frameTime)
  }

  

  enum CodingKeys: String, CodingKey {
    case name = "cm"
    case frameTime = "tm"
  }

  
  let name: String

  
  let frameTime: AnimationFrameTime

}
