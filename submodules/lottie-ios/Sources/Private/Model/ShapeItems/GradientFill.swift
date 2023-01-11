






import Foundation



enum GradientType: Int, Codable {
  case none
  case linear
  case radial
}




final class GradientFill: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: GradientFill.CodingKeys.self)
    opacity = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .opacity)
    startPoint = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .startPoint)
    endPoint = try container.decode(KeyframeGroup<Vector3D>.self, forKey: .endPoint)
    gradientType = try container.decode(GradientType.self, forKey: .gradientType)
    highlightLength = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .highlightLength)
    highlightAngle = try container.decodeIfPresent(KeyframeGroup<Vector1D>.self, forKey: .highlightAngle)
    let colorsContainer = try container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    colors = try colorsContainer.decode(KeyframeGroup<[Double]>.self, forKey: .colors)
    numberOfColors = try colorsContainer.decode(Int.self, forKey: .numberOfColors)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: CodingKeys.opacity)
    opacity = try KeyframeGroup<Vector1D>(dictionary: opacityDictionary)
    let startPointDictionary: [String: Any] = try dictionary.value(for: CodingKeys.startPoint)
    startPoint = try KeyframeGroup<Vector3D>(dictionary: startPointDictionary)
    let endPointDictionary: [String: Any] = try dictionary.value(for: CodingKeys.endPoint)
    endPoint = try KeyframeGroup<Vector3D>(dictionary: endPointDictionary)
    let gradientRawType: Int = try dictionary.value(for: CodingKeys.gradientType)
    guard let gradient = GradientType(rawValue: gradientRawType) else {
      throw InitializableError.invalidInput
    }
    gradientType = gradient
    if let highlightLengthDictionary = dictionary[CodingKeys.highlightLength.rawValue] as? [String: Any] {
      highlightLength = try? KeyframeGroup<Vector1D>(dictionary: highlightLengthDictionary)
    } else {
      highlightLength = nil
    }
    if let highlightAngleDictionary = dictionary[CodingKeys.highlightAngle.rawValue] as? [String: Any] {
      highlightAngle = try? KeyframeGroup<Vector1D>(dictionary: highlightAngleDictionary)
    } else {
      highlightAngle = nil
    }
    let colorsDictionary: [String: Any] = try dictionary.value(for: CodingKeys.colors)
    let nestedColorsDictionary: [String: Any] = try colorsDictionary.value(for: GradientDataKeys.colors)
    colors = try KeyframeGroup<[Double]>(dictionary: nestedColorsDictionary)
    numberOfColors = try colorsDictionary.value(for: GradientDataKeys.numberOfColors)
    try super.init(dictionary: dictionary)
  }

  

  
  let opacity: KeyframeGroup<Vector1D>

  
  let startPoint: KeyframeGroup<Vector3D>

  
  let endPoint: KeyframeGroup<Vector3D>

  
  let gradientType: GradientType

  
  let highlightLength: KeyframeGroup<Vector1D>?

  
  let highlightAngle: KeyframeGroup<Vector1D>?

  
  let numberOfColors: Int

  
  let colors: KeyframeGroup<[Double]>

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(startPoint, forKey: .startPoint)
    try container.encode(endPoint, forKey: .endPoint)
    try container.encode(gradientType, forKey: .gradientType)
    try container.encodeIfPresent(highlightLength, forKey: .highlightLength)
    try container.encodeIfPresent(highlightAngle, forKey: .highlightAngle)
    var colorsContainer = container.nestedContainer(keyedBy: GradientDataKeys.self, forKey: .colors)
    try colorsContainer.encode(numberOfColors, forKey: .numberOfColors)
    try colorsContainer.encode(colors, forKey: .colors)
  }

  

  private enum CodingKeys: String, CodingKey {
    case opacity = "o"
    case startPoint = "s"
    case endPoint = "e"
    case gradientType = "t"
    case highlightLength = "h"
    case highlightAngle = "a"
    case colors = "g"
  }

  private enum GradientDataKeys: String, CodingKey {
    case numberOfColors = "p"
    case colors = "k"
  }
}
