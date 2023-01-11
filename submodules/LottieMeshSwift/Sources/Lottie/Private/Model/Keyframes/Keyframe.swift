






import Foundation
import CoreGraphics


final class Keyframe<T: Interpolatable> {
  
  
  let value: T
  
  let time: CGFloat
  
  let isHold: Bool
  
  let inTangent: Vector2D?
  
  let outTangent: Vector2D?
  
  
  let spatialInTangent: Vector3D?
  
  let spatialOutTangent: Vector3D?
  
  
  init(_ value: T,
       spatialInTangent: Vector3D? = nil,
       spatialOutTangent: Vector3D? = nil) {
    self.value = value
    self.time = 0
    self.isHold = true
    self.inTangent = nil
    self.outTangent = nil
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }
  
  
  init(value: T,
       time: Double,
       isHold: Bool,
       inTangent: Vector2D?,
       outTangent: Vector2D?,
       spatialInTangent: Vector3D? = nil,
       spatialOutTangent: Vector3D? = nil) {
    self.value = value
    self.time = CGFloat(time)
    self.isHold = isHold
    self.outTangent = outTangent
    self.inTangent = inTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }
  
}


final class KeyframeData<T: Codable>: Codable {
  
  
  let startValue: T?
  
  let endValue: T?
  
  let time: Double?
  
  let hold: Int?
  
  
  let inTangent: Vector2D?
  
  let outTangent: Vector2D?
  
  
  let spatialInTangent: Vector3D?
  
  let spatialOutTangent:Vector3D?
  
  init(startValue: T?,
       endValue: T?,
       time: Double?,
       hold: Int?,
       inTangent: Vector2D?,
       outTangent: Vector2D?,
       spatialInTangent: Vector3D?,
       spatialOutTangent: Vector3D?) {
    self.startValue = startValue
    self.endValue = endValue
    self.time = time
    self.hold = hold
    self.inTangent = inTangent
    self.outTangent = outTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }
  
  enum CodingKeys : String, CodingKey {
    case startValue = "s"
    case endValue = "e"
    case time = "t"
    case hold = "h"
    case inTangent = "i"
    case outTangent = "o"
    case spatialInTangent = "ti"
    case spatialOutTangent = "to"
  }
  
  var isHold: Bool {
    if let hold = hold {
      return hold > 0
    }
    return false
  }
}
