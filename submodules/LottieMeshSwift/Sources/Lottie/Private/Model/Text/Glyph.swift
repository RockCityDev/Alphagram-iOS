






import Foundation


final class Glyph: Codable {
  
  
  let character: String
  
  
  let fontSize: Double
  
  
  let fontFamily: String
  
  
  let fontStyle: String
  
  
  let width: Double
  
  
  let shapes: [ShapeItem]
  
  private enum CodingKeys: String, CodingKey {
    case character = "ch"
    case fontSize = "size"
    case fontFamily = "fFamily"
    case fontStyle = "style"
    case width = "w"
    case shapeWrapper = "data"
  }
  
  private enum ShapeKey: String, CodingKey {
    case shapes = "shapes"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Glyph.CodingKeys.self)
    self.character = try container.decode(String.self, forKey: .character)
    self.fontSize = try container.decode(Double.self, forKey: .fontSize)
    self.fontFamily = try container.decode(String.self, forKey: .fontFamily)
    self.fontStyle = try container.decode(String.self, forKey: .fontStyle)
    self.width = try container.decode(Double.self, forKey: .width)
    if container.contains(.shapeWrapper),
      let shapeContainer = try? container.nestedContainer(keyedBy: ShapeKey.self, forKey: .shapeWrapper),
      shapeContainer.contains(.shapes) {
      self.shapes = try shapeContainer.decode([ShapeItem].self, ofFamily: ShapeType.self, forKey: .shapes)
    } else {
      self.shapes = []
    }
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(character, forKey: .character)
    try container.encode(fontSize, forKey: .fontSize)
    try container.encode(fontFamily, forKey: .fontFamily)
    try container.encode(fontStyle, forKey: .fontStyle)
    try container.encode(width, forKey: .width)
    
    var shapeContainer = container.nestedContainer(keyedBy: ShapeKey.self, forKey: .shapeWrapper)
    try shapeContainer.encode(shapes, forKey: .shapes)
  }
}
