




enum Keyframes {
  
  
  
  static func combinedIfPossible<T>(_ groups: [KeyframeGroup<T>]) -> KeyframeGroup<[T]>? {
    guard
      !groups.isEmpty,
      groups.allSatisfy({ $0.hasSameTimingParameters(as: groups[0]) })
    else { return nil }

    var combinedKeyframes = ContiguousArray<Keyframe<[T]>>()

    for index in groups[0].keyframes.indices {
      let baseKeyframe = groups[0].keyframes[index]
      let combinedValues = groups.map { $0.keyframes[index].value }
      combinedKeyframes.append(baseKeyframe.withValue(combinedValues))
    }

    return KeyframeGroup(keyframes: combinedKeyframes)
  }

  
  
  
  static func combinedIfPossible<T>(_ groups: [KeyframeGroup<T>?]) -> KeyframeGroup<[T]>? {
    let nonOptionalGroups = groups.compactMap { $0 }
    guard nonOptionalGroups.count == groups.count else { return nil }
    return combinedIfPossible(nonOptionalGroups)
  }
}

extension KeyframeGroup {
  
  
  func hasSameTimingParameters<T>(as other: KeyframeGroup<T>) -> Bool {
    guard keyframes.count == other.keyframes.count else {
      return false
    }

    return zip(keyframes, other.keyframes).allSatisfy {
      $0.hasSameTimingParameters(as: $1)
    }
  }
}

extension Keyframe {
  
  func hasSameTimingParameters<T>(as other: Keyframe<T>) -> Bool {
    time == other.time
      && isHold == other.isHold
      && inTangent == other.inTangent
      && outTangent == other.outTangent
      && spatialInTangent == other.spatialInTangent
      && spatialOutTangent == other.spatialOutTangent
  }
}
