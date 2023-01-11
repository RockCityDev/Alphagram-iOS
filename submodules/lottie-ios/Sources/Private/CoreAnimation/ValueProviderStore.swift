


import QuartzCore





final class ValueProviderStore {

  

  
  func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    LottieLogger.shared.assert(
      valueProvider.typeErasedStorage.isSupportedByCoreAnimationRenderingEngine,
      """
      The Core Animation rendering engine doesn't support Value Providers that vend a closure,
      because that would require calling the closure on the main thread once per frame.
      """)

    
    LottieLogger.shared.assert(
      keypath.keys.last == PropertyName.color.rawValue,
      "The Core Animation rendering engine currently only supports customizing color values")

    valueProviders.append((keypath: keypath, valueProvider: valueProvider))
  }

  
  
  func customKeyframes<Value>(
    of customizableProperty: CustomizableProperty<Value>,
    for keypath: AnimationKeypath,
    context: LayerAnimationContext)
    throws
    -> KeyframeGroup<Value>?
  {
    guard let anyValueProvider = valueProvider(for: keypath) else {
      return nil
    }

    
    let typeErasedKeyframes: [Keyframe<Any>]
    switch anyValueProvider.typeErasedStorage {
    case .singleValue(let typeErasedValue):
      typeErasedKeyframes = [Keyframe(typeErasedValue)]

    case .keyframes(let keyframes, _):
      typeErasedKeyframes = keyframes

    case .closure:
      try context.logCompatibilityIssue("""
        The Core Animation rendering engine doesn't support Value Providers that vend a closure,
        because that would require calling the closure on the main thread once per frame.
        """)
      return nil
    }

    
    let typedKeyframes = typeErasedKeyframes.compactMap { typeErasedKeyframe -> Keyframe<Value>? in
      guard let convertedValue = customizableProperty.conversion(typeErasedKeyframe.value) else {
        LottieLogger.shared.assertionFailure("""
          Could not convert value of type \(type(of: typeErasedKeyframe.value)) to expected type \(Value.self)
          """)
        return nil
      }

      return typeErasedKeyframe.withValue(convertedValue)
    }

    
    guard typedKeyframes.count == typeErasedKeyframes.count else {
      return nil
    }

    return KeyframeGroup(keyframes: ContiguousArray(typedKeyframes))
  }

  

  private var valueProviders = [(keypath: AnimationKeypath, valueProvider: AnyValueProvider)]()

  
  private func valueProvider(for keypath: AnimationKeypath) -> AnyValueProvider? {
    
    
    valueProviders.last(where: { registeredKeypath, _ in
      keypath.matches(registeredKeypath)
    })?.valueProvider
  }

}

extension AnyValueProviderStorage {
  
  
  var isSupportedByCoreAnimationRenderingEngine: Bool {
    switch self {
    case .singleValue, .keyframes:
      return true
    case .closure:
      return false
    }
  }
}

extension AnimationKeypath {
  
  
  func matches(_ keypath: AnimationKeypath) -> Bool {
    var regex = "^" 
      + keypath.keys.joined(separator: "\\.") // match this keypath, escaping "." characters
      + "$" 

    
    //  - "**.Color" matches both "Layer 1.Color" and "Layer 1.Layer 2.Color"
    regex = regex.replacingOccurrences(of: "**", with: ".+")

    
    //  - "*.Color" matches "Layer 1.Color" but not "Layer 1.Layer 2.Color"
    regex = regex.replacingOccurrences(of: "*", with: "[^.]+")

    return fullPath.range(of: regex, options: .regularExpression) != nil
  }
}
