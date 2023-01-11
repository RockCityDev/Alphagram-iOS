






import CoreGraphics
import Foundation




final class KeyframeInterpolator<ValueType>: ValueProvider where ValueType: AnyInterpolatable {

  

  init(keyframes: ContiguousArray<Keyframe<ValueType>>) {
    self.keyframes = keyframes
  }

  

  let keyframes: ContiguousArray<Keyframe<ValueType>>

  var valueType: Any.Type {
    ValueType.self
  }

  var storage: ValueProviderStorage<ValueType> {
    .closure { [self] frame in
      
      updateSpanIndices(frame: frame)
      lastUpdatedFrame = frame
      
      let progress: CGFloat
      let value: ValueType

      if
        let leading = leadingKeyframe,
        let trailing = trailingKeyframe
      {
        
        progress = leading.interpolatedProgress(trailing, keyTime: frame)
        value = leading.interpolate(to: trailing, progress: progress)
      } else if let leading = leadingKeyframe {
        progress = 0
        value = leading.value
      } else if let trailing = trailingKeyframe {
        progress = 1
        value = trailing.value
      } else {
        
        progress = 0
        value = keyframes[0].value
      }
      return value
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  func hasUpdate(frame: CGFloat) -> Bool {
    if lastUpdatedFrame == nil {
      return true
    }

    if
      let leading = leadingKeyframe,
      trailingKeyframe == nil,
      leading.time < frame
    {
      
      return false
    }
    if
      let trailing = trailingKeyframe,
      leadingKeyframe == nil,
      frame < trailing.time
    {
      
      return false
    }
    if
      let leading = leadingKeyframe,
      let trailing = trailingKeyframe,
      leading.isHold,
      leading.time < frame,
      frame < trailing.time
    {
      return false
    }
    return true
  }

  

  fileprivate var lastUpdatedFrame: CGFloat?

  fileprivate var leadingIndex: Int? = nil
  fileprivate var trailingIndex: Int? = nil
  fileprivate var leadingKeyframe: Keyframe<ValueType>? = nil
  fileprivate var trailingKeyframe: Keyframe<ValueType>? = nil

  
  fileprivate func updateSpanIndices(frame: CGFloat) {
    guard keyframes.count > 0 else {
      leadingIndex = nil
      trailingIndex = nil
      leadingKeyframe = nil
      trailingKeyframe = nil
      return
    }

    
    
    
    
    
    
    
    
    
    
    

    if keyframes.count == 1 {
      
      leadingIndex = 0
      trailingIndex = nil
      leadingKeyframe = keyframes[0]
      trailingKeyframe = nil
      return
    }

    
    if
      leadingIndex == nil &&
      trailingIndex == nil
    {
      if frame < keyframes[0].time {
        
        trailingIndex = 0
      } else {
        
        leadingIndex = 0
        trailingIndex = 1
      }
    }

    if
      let currentTrailing = trailingIndex,
      keyframes[currentTrailing].time <= frame
    {
      
      var newLeading = currentTrailing
      var keyframeFound = false
      while !keyframeFound {

        leadingIndex = newLeading
        trailingIndex = keyframes.validIndex(newLeading + 1)

        guard let trailing = trailingIndex else {
          
          keyframeFound = true
          continue
        }
        if frame < keyframes[trailing].time {
          
          keyframeFound = true
          continue
        }
        
        newLeading = trailing
      }

    } else if
      let currentLeading = leadingIndex,
      frame < keyframes[currentLeading].time
    {

      
      var newTrailing = currentLeading

      var keyframeFound = false
      while !keyframeFound {

        leadingIndex = keyframes.validIndex(newTrailing - 1)
        trailingIndex = newTrailing

        guard let leading = leadingIndex else {
          
          keyframeFound = true
          continue
        }
        if keyframes[leading].time <= frame {
          
          keyframeFound = true
          continue
        }
        
        newTrailing = leading
      }
    }
    if let keyFrame = leadingIndex {
      leadingKeyframe = keyframes[keyFrame]
    } else {
      leadingKeyframe = nil
    }

    if let keyFrame = trailingIndex {
      trailingKeyframe = keyframes[keyFrame]
    } else {
      trailingKeyframe = nil
    }
  }
}

extension Array {

  fileprivate func validIndex(_ index: Int) -> Int? {
    if 0 <= index, index < endIndex {
      return index
    }
    return nil
  }

}

extension ContiguousArray {

  fileprivate func validIndex(_ index: Int) -> Int? {
    if 0 <= index, index < endIndex {
      return index
    }
    return nil
  }

}
