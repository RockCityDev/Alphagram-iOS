







public final class Keyframe<T> {

  

  
  public init(
    _ value: T,
    spatialInTangent: Vector3D? = nil,
    spatialOutTangent: Vector3D? = nil)
  {
    self.value = value
    time = 0
    isHold = true
    inTangent = nil
    outTangent = nil
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  
  public init(
    value: T,
    time: AnimationFrameTime,
    isHold: Bool = false,
    inTangent: Vector2D? = nil,
    outTangent: Vector2D? = nil,
    spatialInTangent: Vector3D? = nil,
    spatialOutTangent: Vector3D? = nil)
  {
    self.value = value
    self.time = time
    self.isHold = isHold
    self.outTangent = outTangent
    self.inTangent = inTangent
    self.spatialInTangent = spatialInTangent
    self.spatialOutTangent = spatialOutTangent
  }

  

  
  public let value: T
  
  public let time: AnimationFrameTime
  
  public let isHold: Bool
  
  public let inTangent: Vector2D?
  
  public let outTangent: Vector2D?

  
  public let spatialInTangent: Vector3D?
  
  public let spatialOutTangent: Vector3D?
}



extension Keyframe: Equatable where T: Equatable {
  public static func == (lhs: Keyframe<T>, rhs: Keyframe<T>) -> Bool {
    lhs.value == rhs.value
      && lhs.time == rhs.time
      && lhs.isHold == rhs.isHold
      && lhs.inTangent == rhs.inTangent
      && lhs.outTangent == rhs.outTangent
      && lhs.spatialInTangent == rhs.spatialOutTangent
      && lhs.spatialOutTangent == rhs.spatialOutTangent
  }
}



extension Keyframe: Hashable where T: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(value)
    hasher.combine(time)
    hasher.combine(isHold)
    hasher.combine(inTangent)
    hasher.combine(outTangent)
    hasher.combine(spatialInTangent)
    hasher.combine(spatialOutTangent)
  }
}
