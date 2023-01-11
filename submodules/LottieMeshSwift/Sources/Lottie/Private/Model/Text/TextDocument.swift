






import Foundation

enum TextJustification: Int, Codable {
  case left
  case right
  case center
}

final class TextDocument: Codable {
  
  
  let text: String
  
  
  let fontSize: Double
  
  
  let fontFamily: String
  
  
  let justification: TextJustification
  
  
  let tracking: Int
  
  
  let lineHeight: Double
  
  
  let baseline: Double?
  
  
  let fillColorData: Color?
  
  
  let strokeColorData: Color?
  
  
  let strokeWidth: Double?
  
  
  let strokeOverFill: Bool?
  
  let textFramePosition: Vector3D?
  
  let textFrameSize: Vector3D?
  
  private enum CodingKeys : String, CodingKey {
    case text = "t"
    case fontSize = "s"
    case fontFamily = "f"
    case justification = "j"
    case tracking = "tr"
    case lineHeight = "lh"
    case baseline = "ls"
    case fillColorData = "fc"
    case strokeColorData = "sc"
    case strokeWidth = "sw"
    case strokeOverFill = "of"
    case textFramePosition = "ps"
    case textFrameSize = "sz"
  }
}
