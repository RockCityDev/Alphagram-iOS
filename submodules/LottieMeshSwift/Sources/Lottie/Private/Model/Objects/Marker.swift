






import Foundation


final class Marker: Codable {
  
  
  let name: String
  
  
  let frameTime: AnimationFrameTime
  
  enum CodingKeys : String, CodingKey {
    case name = "cm"
    case frameTime = "tm"
  }
}
