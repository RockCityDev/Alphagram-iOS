






import Foundation



enum FillRule: Int, Codable {
  case none
  case nonZeroWinding
  case evenOdd
}




final class Fill: ShapeItem {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Fill.CodingKeys.self)
    opacity = try container.decode(KeyframeGroup<Vector1D>.self, forKey: .opacity)
    color = try container.decode(KeyframeGroup<Color>.self, forKey: .color)
    fillRule = try container.decodeIfPresent(FillRule.self, forKey: .fillRule) ?? .nonZeroWinding
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    let opacityDictionary: [String: Any] = try dictionary.value(for: CodingKeys.opacity)
    opacity = try KeyframeGroup<Vector1D>(dictionary: opacityDictionary)
    let colorDictionary: [String: Any] = try dictionary.value(for: CodingKeys.color)
    color = try KeyframeGroup<Color>(dictionary: colorDictionary)
    if
      let fillRuleRawValue = dictionary[CodingKeys.fillRule.rawValue] as? Int,
      let fillRule = FillRule(rawValue: fillRuleRawValue)
    {
      self.fillRule = fillRule
    } else {
      fillRule = .nonZeroWinding
    }
    try super.init(dictionary: dictionary)
  }

  

  
  let opacity: KeyframeGroup<Vector1D>

  
  let color: KeyframeGroup<Color>

  let fillRule: FillRule

  override func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(opacity, forKey: .opacity)
    try container.encode(color, forKey: .color)
    try container.encode(fillRule, forKey: .fillRule)
  }

  

  private enum CodingKeys: String, CodingKey {
    case opacity = "o"
    case color = "c"
    case fillRule = "r"
  }
}
