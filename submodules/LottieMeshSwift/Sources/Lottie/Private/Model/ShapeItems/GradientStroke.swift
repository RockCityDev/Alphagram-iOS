






import Foundation

enum LineCap: Int, Codable {
  case none
  case butt
  case round
  case square
}

enum LineJoin: Int, Codable {
  case none
  case miter
  case round
  case bevel
}


final class GradientStroke: ShapeItem {
  
  
  let opacity: KeyframeGroup<Vector1D>
  
  
  let startPoint: KeyframeGroup<Vector3D>
  
  
  let endPoint: KeyframeGroup<Vector3D>
  
  
  let gradientType: GradientType
  
  
  let highlightLength: KeyframeGroup<Vector1D>?
  
  
  let highlightAngle: KeyframeGroup<Vector1D>?
  
  
  let numberOfColors: Int
  
  
  let colors: KeyframeGroup<[Double]>
  
  
  let width: KeyframeGroup<Vector1D>
  
  
  let lineCap: LineCap
  
  
  let lineJoin: LineJoin
  
  
  let miterLimit: Double
  
  
  let dashPattern: [DashElement]?
  
  private enum CodingKeys : String, CodingKey {
    case opacity = "o"
    case startPoint = "s"
    case endPoint = "e"
    case gradientType = "t"
    case highlightLength = "h"
    case highlightAngle = "a"
    case colors = "g"
    case width = "w"
    case lineCap = "lc"
    case lineJoin = "lj"
    case miterLimit = "ml"
    case dashPattern = "d"
  }
  
  private enum GradientDataKeys : String, CodingKey {
    case numberOfColors = "p"
    case colors = "k"
  }
  
  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: GradientStroke.CodingKeys.self)
    self.opacity = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .opacity)
    self.startPoint = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .startPoint)
    self.endPoint = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .endPoint)
    self.gradientType = try container.decode(GradientType.self, forKey: .gradientType)
    self.highlightLength = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .highlightLength)
    self.highlightAngle = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .highlightAngle)
    self.width = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .width)
    self.lineCap = try container.decodeIfPresent(LineCap.self, forKey: .lineCap) ?? .round
    self.lineJoin = try container.decodeIfPresent(LineJoin.self, forKey: .lineJoin) ?? .round
    self.miterLimit = try container.decodeIfPresent(Double.self, forKey: .miterLimit) ?? 4
    
    let colorsContainer = try container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    self.colors = try colorsContainer.decode(KeyframeGroup<[Double]>.self, forKey: .colors)
    self.numberOfColors = try colorsContainer.decode(Int.self, forKey: .numberOfColors)
    self.dashPattern = try container.decodeIfPresent([DashElement].self, forKey: .dashPattern)
    try super.init(from: decoder)
  }
  
  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(startPoint, forKey: .startPoint)
    try container.encode(endPoint, forKey: .endPoint)
    try container.encode(gradientType, forKey: .gradientType)
    try container.encodeIfPresent(highlightLength, forKey: .highlightLength)
    try container.encodeIfPresent(highlightAngle, forKey: .highlightAngle)
    try container.encode(width, forKey: .width)
    try container.encode(lineCap, forKey: .lineCap)
    try container.encode(lineJoin, forKey: .lineJoin)
    try container.encode(miterLimit, forKey: .miterLimit)
    var colorsContainer = container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    try colorsContainer.encode(numberOfColors, forKey: .numberOfColors)
    try colorsContainer.encode(colors, forKey: .colors)
    try container.encodeIfPresent(dashPattern, forKey: .dashPattern)
  }
  
}
