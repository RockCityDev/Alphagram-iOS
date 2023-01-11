






import Foundation



enum TextJustification: Int, Codable {
  case left
  case right
  case center
}



final class TextDocument: Codable, DictionaryInitializable, AnyInitializable {

  

  init(dictionary: [String: Any]) throws {
    text = try dictionary.value(for: CodingKeys.text)
    fontSize = try dictionary.value(for: CodingKeys.fontSize)
    fontFamily = try dictionary.value(for: CodingKeys.fontFamily)
    let justificationValue: Int = try dictionary.value(for: CodingKeys.justification)
    guard let justification = TextJustification(rawValue: justificationValue) else {
      throw InitializableError.invalidInput
    }
    self.justification = justification
    tracking = try dictionary.value(for: CodingKeys.tracking)
    lineHeight = try dictionary.value(for: CodingKeys.lineHeight)
    baseline = try dictionary.value(for: CodingKeys.baseline)
    if let fillColorRawValue = dictionary[CodingKeys.fillColorData.rawValue] {
      fillColorData = try? Color(value: fillColorRawValue)
    } else {
      fillColorData = nil
    }
    if let strokeColorRawValue = dictionary[CodingKeys.strokeColorData.rawValue] {
      strokeColorData = try? Color(value: strokeColorRawValue)
    } else {
      strokeColorData = nil
    }
    strokeWidth = try? dictionary.value(for: CodingKeys.strokeWidth)
    strokeOverFill = try? dictionary.value(for: CodingKeys.strokeOverFill)
    if let textFramePositionRawValue = dictionary[CodingKeys.textFramePosition.rawValue] {
      textFramePosition = try? Vector3D(value: textFramePositionRawValue)
    } else {
      textFramePosition = nil
    }
    if let textFrameSizeRawValue = dictionary[CodingKeys.textFrameSize.rawValue] {
      textFrameSize = try? Vector3D(value: textFrameSizeRawValue)
    } else {
      textFrameSize = nil
    }
  }

  convenience init(value: Any) throws {
    guard let dictionary = value as? [String: Any] else {
      throw InitializableError.invalidInput
    }
    try self.init(dictionary: dictionary)
  }

  

  
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

  

  private enum CodingKeys: String, CodingKey {
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
