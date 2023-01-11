




extension KeyframeGroup {
  
  
  
  
  
  
  
  
  
  
  
  
  
  func exactlyOneKeyframe(
    context: CompatibilityTrackerProviding,
    description: String,
    fileID _: StaticString = #fileID,
    line _: UInt = #line)
    throws
    -> Keyframe<T>
  {
    try context.compatibilityAssert(
      keyframes.count == 1,
      """
      The Core Animation rendering engine does not support animating multiple keyframes
      for \(description) values (due to limitations of Core Animation `CAKeyframeAnimation`s).
      """)

    return keyframes[0]
  }
}
