






import CoreGraphics
import Foundation








final class KeyframeData<T> {

  

  init(
    startValue: T?,
    endValue: T?,
    time: AnimationFrameTime?,
    hold: Int?,
    inTangent: Vector2D?,
    outTangent: Vector2D?,
    spatialInTangent: Vector3D?,
    spatialOutTangent: Vector3D?)
  {
    self.startValue = startValue
    self.endValue = endValue
    self.time = time
    self.hold = hold
    self.inTangent = inTangent
    self.outTangent = outTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  

  enum CodingKeys: String, CodingKey {
    case startValue = "s"
    case endValue = "e"
    case time = "t"
    case hold = "h"
    case inTangent = "i"
    case outTangent = "o"
    case spatialInTangent = "ti"
    case spatialOutTangent = "to"
  }

  
  let startValue: T?
  
  let endValue: T?
  
  let time: AnimationFrameTime?
  
  let hold: Int?

  
  let inTangent: Vector2D?
  
  let outTangent: Vector2D?

  
  let spatialInTangent: Vector3D?
  
  let spatialOutTangent: Vector3D?

  var isHold: Bool {
    if let hold = hold {
      return hold > 0
    }
    return false
  }
}



extension KeyframeData: Encodable where T: Encodable { }



extension KeyframeData: Decodable where T: Decodable { }



extension KeyframeData: DictionaryInitializable where T: AnyInitializable {
  convenience init(dictionary: [String: Any]) throws {
    let startValue = try? dictionary[CodingKeys.startValue.rawValue].flatMap(T.init)
    let endValue = try? dictionary[CodingKeys.endValue.rawValue].flatMap(T.init)
    let time: AnimationFrameTime? = try? dictionary.value(for: CodingKeys.time)
    let hold: Int? = try? dictionary.value(for: CodingKeys.hold)
    let inTangent: Vector2D? = try? dictionary.value(for: CodingKeys.inTangent)
    let outTangent: Vector2D? = try? dictionary.value(for: CodingKeys.outTangent)
    let spatialInTangent: Vector3D? = try? dictionary.value(for: CodingKeys.spatialInTangent)
    let spatialOutTangent: Vector3D? = try? dictionary.value(for: CodingKeys.spatialOutTangent)

    self.init(
      startValue: startValue,
      endValue: endValue,
      time: time,
      hold: hold,
      inTangent: inTangent,
      outTangent: outTangent,
      spatialInTangent: spatialInTangent,
      spatialOutTangent: spatialOutTangent)
  }
}
