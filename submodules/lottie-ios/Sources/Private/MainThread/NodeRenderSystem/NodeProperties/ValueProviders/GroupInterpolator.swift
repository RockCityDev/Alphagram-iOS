






import CoreGraphics
import Foundation


final class GroupInterpolator<ValueType>: ValueProvider where ValueType: Interpolatable {

  

  
  init(keyframeGroups: ContiguousArray<ContiguousArray<Keyframe<ValueType>>>) {
    keyframeInterpolators = ContiguousArray(keyframeGroups.map({ KeyframeInterpolator(keyframes: $0) }))
  }

  

  let keyframeInterpolators: ContiguousArray<KeyframeInterpolator<ValueType>>

  var valueType: Any.Type {
    [ValueType].self
  }

  var storage: ValueProviderStorage<[ValueType]> {
    .closure { frame in
      self.keyframeInterpolators.map({ $0.value(frame: frame) as! ValueType })
    }
  }

  func hasUpdate(frame: CGFloat) -> Bool {
    let updated = keyframeInterpolators.first(where: { $0.hasUpdate(frame: frame) })
    return updated != nil
  }
}
