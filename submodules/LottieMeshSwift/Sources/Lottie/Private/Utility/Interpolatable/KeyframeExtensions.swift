






import Foundation
import CoreGraphics

extension Keyframe {
  
  
  func interpolatedProgress(_ to: Keyframe, keyTime: CGFloat) -> CGFloat {
    let startTime = time
    let endTime = to.time
    if keyTime <= startTime {
      return 0
    }
    if endTime <= keyTime {
      return 1
    }
    
    if isHold {
      return 0
    }
    
    let outTanPoint = outTangent?.pointValue ?? .zero
    let inTanPoint = to.inTangent?.pointValue ?? CGPoint(x: 1, y: 1)
    var progress: CGFloat = keyTime.remap(fromLow: startTime, fromHigh: endTime, toLow: 0, toHigh: 1)
    if !outTanPoint.isZero || !inTanPoint.equalTo(CGPoint(x: 1, y: 1)) {
      
      progress = progress.cubicBezierInterpolate(.zero, outTanPoint, inTanPoint, CGPoint(x: 1, y: 1))
    }
    return progress
  }
  
  
  func interpolate(_ to: Keyframe, progress: CGFloat) -> T {
    return value.interpolateTo(to.value, amount: progress, spatialOutTangent: spatialOutTangent?.pointValue, spatialInTangent: to.spatialInTangent?.pointValue)
  }
  
}
