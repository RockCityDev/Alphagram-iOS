






import CoreGraphics
import Foundation









public protocol AnyValueProvider {

  
  var valueType: Any.Type { get }

  
  var typeErasedStorage: AnyValueProviderStorage { get }

  
  func hasUpdate(frame: AnimationFrameTime) -> Bool

}

extension AnyValueProvider {
  
  public func value(frame: AnimationFrameTime) -> Any {
    typeErasedStorage.value(frame: frame)
  }
}




protocol ValueProvider: AnyValueProvider {
  associatedtype Value: AnyInterpolatable

  
  var storage: ValueProviderStorage<Value> { get }
}

extension ValueProvider {
  public var typeErasedStorage: AnyValueProviderStorage {
    switch storage {
    case .closure(let typedClosure):
      return .closure(typedClosure)

    case .singleValue(let typedValue):
      return .singleValue(typedValue)

    case .keyframes(let keyframes):
      return .keyframes(
        keyframes.map { keyframe in
          keyframe.withValue(keyframe.value as Any)
        },
        interpolate: storage.value(frame:))
    }
  }
}




public enum ValueProviderStorage<T: AnyInterpolatable> {
  
  case singleValue(T)

  
  
  
  
  
  
  case keyframes([Keyframe<T>])

  
  
  case closure((AnimationFrameTime) -> T)

  

  func value(frame: AnimationFrameTime) -> T {
    switch self {
    case .singleValue(let value):
      return value

    case .closure(let closure):
      return closure(frame)

    case .keyframes(let keyframes):
      return KeyframeInterpolator(keyframes: ContiguousArray(keyframes)).storage.value(frame: frame)
    }
  }
}




public enum AnyValueProviderStorage {
  
  case singleValue(Any)

  
  
  
  case keyframes([Keyframe<Any>], interpolate: (AnimationFrameTime) -> Any)

  
  case closure((AnimationFrameTime) -> Any)

  

  func value(frame: AnimationFrameTime) -> Any {
    switch self {
    case .singleValue(let value):
      return value

    case .closure(let closure):
      return closure(frame)

    case .keyframes(_, let valueForFrame):
      return valueForFrame(frame)
    }
  }
}
