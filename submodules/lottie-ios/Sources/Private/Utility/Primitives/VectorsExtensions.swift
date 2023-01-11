






import CoreGraphics
import Foundation
import QuartzCore




extension Vector1D: Codable {

  

  public init(from decoder: Decoder) throws {
    
    do {
      var container = try decoder.unkeyedContainer()
      value = try container.decode(Double.self)
    } catch {
      value = try decoder.singleValueContainer().decode(Double.self)
    }
  }

  

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }

  

  var cgFloatValue: CGFloat {
    CGFloat(value)
  }

}



extension Vector1D: AnyInitializable {

  init(value: Any) throws {
    if
      let array = value as? [Double],
      let double = array.first
    {
      self.value = double
    } else if let double = value as? Double {
      self.value = double
    } else {
      throw InitializableError.invalidInput
    }
  }

}

extension Double {
  var vectorValue: Vector1D {
    Vector1D(self)
  }
}




public struct Vector2D: Codable, Hashable {

  

  init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Vector2D.CodingKeys.self)

    do {
      let xValue: [Double] = try container.decode([Double].self, forKey: .x)
      x = xValue[0]
    } catch {
      x = try container.decode(Double.self, forKey: .x)
    }

    do {
      let yValue: [Double] = try container.decode([Double].self, forKey: .y)
      y = yValue[0]
    } catch {
      y = try container.decode(Double.self, forKey: .y)
    }
  }

  

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: Vector2D.CodingKeys.self)
    try container.encode(x, forKey: .x)
    try container.encode(y, forKey: .y)
  }

  

  var x: Double
  var y: Double

  var pointValue: CGPoint {
    CGPoint(x: x, y: y)
  }

  

  private enum CodingKeys: String, CodingKey {
    case x
    case y
  }
}



extension Vector2D: AnyInitializable {

  init(value: Any) throws {
    guard let dictionary = value as? [String: Any] else {
      throw InitializableError.invalidInput
    }

    if
      let array = dictionary[CodingKeys.x.rawValue] as? [Double],
      let double = array.first
    {
      x = double
    } else if let double = dictionary[CodingKeys.x.rawValue] as? Double {
      x = double
    } else {
      throw InitializableError.invalidInput
    }
    if
      let array = dictionary[CodingKeys.y.rawValue] as? [Double],
      let double = array.first
    {
      y = double
    } else if let double = dictionary[CodingKeys.y.rawValue] as? Double {
      y = double
    } else {
      throw InitializableError.invalidInput
    }
  }
}

extension CGPoint {
  var vector2dValue: Vector2D {
    Vector2D(x: Double(x), y: Double(y))
  }
}






extension Vector3D: Codable {

  

  init(x: CGFloat, y: CGFloat, z: CGFloat) {
    self.x = Double(x)
    self.y = Double(y)
    self.z = Double(z)
  }

  public init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()

    if !container.isAtEnd {
      x = try container.decode(Double.self)
    } else {
      x = 0
    }

    if !container.isAtEnd {
      y = try container.decode(Double.self)
    } else {
      y = 0
    }

    if !container.isAtEnd {
      z = try container.decode(Double.self)
    } else {
      z = 0
    }
  }

  

  public func encode(to encoder: Encoder) throws {
    var container = encoder.unkeyedContainer()
    try container.encode(x)
    try container.encode(y)
    try container.encode(z)
  }

}



extension Vector3D: AnyInitializable {

  init(value: Any) throws {
    guard var array = value as? [Double] else {
      throw InitializableError.invalidInput
    }
    x = array.count > 0 ? array.removeFirst() : 0
    y = array.count > 0 ? array.removeFirst() : 0
    z = array.count > 0 ? array.removeFirst() : 0
  }

}

extension Vector3D {
  public var pointValue: CGPoint {
    CGPoint(x: x, y: y)
  }

  public var sizeValue: CGSize {
    CGSize(width: x, height: y)
  }
}

extension CGPoint {
  var vector3dValue: Vector3D {
    Vector3D(x: x, y: y, z: 0)
  }
}

extension CGSize {
  var vector3dValue: Vector3D {
    Vector3D(x: width, y: height, z: 1)
  }
}

extension CATransform3D {

  static func makeSkew(skew: CGFloat, skewAxis: CGFloat) -> CATransform3D {
    let mCos = cos(skewAxis.toRadians())
    let mSin = sin(skewAxis.toRadians())
    let aTan = tan(skew.toRadians())

    let transform1 = CATransform3D(
      m11: mCos,
      m12: mSin,
      m13: 0,
      m14: 0,
      m21: -mSin,
      m22: mCos,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1)

    let transform2 = CATransform3D(
      m11: 1,
      m12: 0,
      m13: 0,
      m14: 0,
      m21: aTan,
      m22: 1,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1)

    let transform3 = CATransform3D(
      m11: mCos,
      m12: -mSin,
      m13: 0,
      m14: 0,
      m21: mSin,
      m22: mCos,
      m23: 0,
      m24: 0,
      m31: 0,
      m32: 0,
      m33: 1,
      m34: 0,
      m41: 0,
      m42: 0,
      m43: 0,
      m44: 1)
    return CATransform3DConcat(transform3, CATransform3DConcat(transform2, transform1))
  }

  static func makeTransform(
    anchor: CGPoint,
    position: CGPoint,
    scale: CGSize,
    rotation: CGFloat,
    skew: CGFloat?,
    skewAxis: CGFloat?)
    -> CATransform3D
  {
    if let skew = skew, let skewAxis = skewAxis {
      return CATransform3DMakeTranslation(position.x, position.y, 0).rotated(rotation).skewed(skew: -skew, skewAxis: skewAxis)
        .scaled(scale * 0.01).translated(anchor * -1)
    }
    return CATransform3DMakeTranslation(position.x, position.y, 0).rotated(rotation).scaled(scale * 0.01).translated(anchor * -1)
  }

  func rotated(_ degrees: CGFloat) -> CATransform3D {
    CATransform3DRotate(self, degrees.toRadians(), 0, 0, 1)
  }

  func translated(_ translation: CGPoint) -> CATransform3D {
    CATransform3DTranslate(self, translation.x, translation.y, 0)
  }

  func scaled(_ scale: CGSize) -> CATransform3D {
    CATransform3DScale(self, scale.width, scale.height, 1)
  }

  func skewed(skew: CGFloat, skewAxis: CGFloat) -> CATransform3D {
    CATransform3DConcat(CATransform3D.makeSkew(skew: skew, skewAxis: skewAxis), self)
  }
}
