


import CoreGraphics




public protocol Interpolatable: AnyInterpolatable {
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  func interpolate(to: Self, amount: CGFloat) -> Self
}







public protocol SpatialInterpolatable: AnyInterpolatable {
  
  
  
  
  
  
  func interpolate(
    to: Self,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> Self
}





public protocol AnyInterpolatable {
  
  
  
  func _interpolate(
    to: Self,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> Self
}

extension Interpolatable {
  public func _interpolate(
    to: Self,
    amount: CGFloat,
    spatialOutTangent _: CGPoint?,
    spatialInTangent _: CGPoint?)
    -> Self
  {
    interpolate(to: to, amount: amount)
  }
}

extension SpatialInterpolatable {
  
  
  public func interpolate(to: Self, amount: CGFloat) -> Self {
    interpolate(
      to: to,
      amount: amount,
      spatialOutTangent: nil,
      spatialInTangent: nil)
  }

  public func _interpolate(
    to: Self,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> Self
  {
    interpolate(
      to: to,
      amount: amount,
      spatialOutTangent: spatialOutTangent,
      spatialInTangent: spatialInTangent)
  }
}



extension Double: Interpolatable { }



extension CGFloat: Interpolatable { }



extension Float: Interpolatable { }

extension Interpolatable where Self: BinaryFloatingPoint {
  public func interpolate(to: Self, amount: CGFloat) -> Self {
    self + ((to - self) * Self(amount))
  }
}



extension CGRect: Interpolatable {
  public func interpolate(to: CGRect, amount: CGFloat) -> CGRect {
    CGRect(
      x: origin.x.interpolate(to: to.origin.x, amount: amount),
      y: origin.y.interpolate(to: to.origin.y, amount: amount),
      width: width.interpolate(to: to.width, amount: amount),
      height: height.interpolate(to: to.height, amount: amount))
  }
}



extension CGSize: Interpolatable {
  public func interpolate(to: CGSize, amount: CGFloat) -> CGSize {
    CGSize(
      width: width.interpolate(to: to.width, amount: amount),
      height: height.interpolate(to: to.height, amount: amount))
  }
}



extension CGPoint: SpatialInterpolatable {
  public func interpolate(
    to: CGPoint,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> CGPoint
  {
    guard
      let outTan = spatialOutTangent,
      let inTan = spatialInTangent
    else {
      return CGPoint(
        x: x.interpolate(to: to.x, amount: amount),
        y: y.interpolate(to: to.y, amount: amount))
    }

    let cp1 = self + outTan
    let cp2 = to + inTan
    return interpolate(to, outTangent: cp1, inTangent: cp2, amount: amount)
  }
}



extension Color: Interpolatable {
  public func interpolate(to: Color, amount: CGFloat) -> Color {
    Color(
      r: r.interpolate(to: to.r, amount: amount),
      g: g.interpolate(to: to.g, amount: amount),
      b: b.interpolate(to: to.b, amount: amount),
      a: a.interpolate(to: to.a, amount: amount))
  }
}



extension Vector1D: Interpolatable {
  public func interpolate(to: Vector1D, amount: CGFloat) -> Vector1D {
    value.interpolate(to: to.value, amount: amount).vectorValue
  }
}



extension Vector2D: SpatialInterpolatable {
  public func interpolate(
    to: Vector2D,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> Vector2D
  {
    pointValue.interpolate(
      to: to.pointValue,
      amount: amount,
      spatialOutTangent: spatialOutTangent,
      spatialInTangent: spatialInTangent)
      .vector2dValue
  }
}



extension Vector3D: SpatialInterpolatable {
  public func interpolate(
    to: Vector3D,
    amount: CGFloat,
    spatialOutTangent: CGPoint?,
    spatialInTangent: CGPoint?)
    -> Vector3D
  {
    if spatialInTangent != nil || spatialOutTangent != nil {
      
      let point = pointValue.interpolate(
        to: to.pointValue,
        amount: amount,
        spatialOutTangent: spatialOutTangent,
        spatialInTangent: spatialInTangent)

      return Vector3D(
        x: point.x,
        y: point.y,
        z: CGFloat(z.interpolate(to: to.z, amount: amount)))
    }

    return Vector3D(
      x: x.interpolate(to: to.x, amount: amount),
      y: y.interpolate(to: to.y, amount: amount),
      z: z.interpolate(to: to.z, amount: amount))
  }
}



extension Array: Interpolatable, AnyInterpolatable where Element: Interpolatable {
  public func interpolate(to: [Element], amount: CGFloat) -> [Element] {
    LottieLogger.shared.assert(
      count == to.count,
      "When interpolating Arrays, both array sound have the same element count.")

    return zip(self, to).map { lhs, rhs in
      lhs.interpolate(to: rhs, amount: amount)
    }
  }
}
