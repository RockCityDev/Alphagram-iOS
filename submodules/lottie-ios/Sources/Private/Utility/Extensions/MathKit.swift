







import CoreGraphics
import Foundation

extension Int {
  var cgFloat: CGFloat {
    CGFloat(self)
  }
}

extension Double {
  var cgFloat: CGFloat {
    CGFloat(self)
  }
}



extension CGFloat {

  func remap(fromLow: CGFloat, fromHigh: CGFloat, toLow: CGFloat, toHigh: CGFloat) -> CGFloat {
    guard (fromHigh - fromLow) != 0 else {
      
      return 0
    }
    return toLow + (self - fromLow) * (toHigh - toLow) / (fromHigh - fromLow)
  }

  
  
  
  func clamp(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
    CGFloat(Double(self).clamp(Double(a), Double(b)))
  }

  
  
  func diff(_ a: CGFloat, absolute: Bool = true) -> CGFloat {
    absolute ? abs(a - self) : a - self
  }

  func toRadians() -> CGFloat { self * .pi / 180 }
  func toDegrees() -> CGFloat { self * 180 / .pi }

}



extension Double {

  func remap(fromLow: Double, fromHigh: Double, toLow: Double, toHigh: Double) -> Double {
    toLow + (self - fromLow) * (toHigh - toLow) / (fromHigh - fromLow)
  }

  
  
  
  func clamp(_ a: Double, _ b: Double) -> Double {
    let minValue = a <= b ? a : b
    let maxValue = a <= b ? b : a
    return max(min(self, maxValue), minValue)
  }

}

extension CGRect {

  

  
  init(center: CGPoint, size: CGSize) {
    self.init(
      x: center.x - (size.width * 0.5),
      y: center.y - (size.height * 0.5),
      width: size.width,
      height: size.height)
  }

  

  
  var area: CGFloat {
    width * height
  }

  
  var center: CGPoint {
    get {
      CGPoint(x: midX, y: midY)
    }
    set {
      origin = CGPoint(
        x: newValue.x - (size.width * 0.5),
        y: newValue.y - (size.height * 0.5))
    }
  }

  
  var topLeft: CGPoint {
    get {
      CGPoint(x: minX, y: minY)
    }
    set {
      origin = CGPoint(
        x: newValue.x,
        y: newValue.y)
    }
  }

  
  var bottomLeft: CGPoint {
    get {
      CGPoint(x: minX, y: maxY)
    }
    set {
      origin = CGPoint(
        x: newValue.x,
        y: newValue.y - size.height)
    }
  }

  
  var topRight: CGPoint {
    get {
      CGPoint(x: maxX, y: minY)
    }
    set {
      origin = CGPoint(
        x: newValue.x - size.width,
        y: newValue.y)
    }
  }

  
  var bottomRight: CGPoint {
    get {
      CGPoint(x: maxX, y: maxY)
    }
    set {
      origin = CGPoint(
        x: newValue.x - size.width,
        y: newValue.y - size.height)
    }
  }

}

extension CGSize {

  
  static func +(left: CGSize, right: CGSize) -> CGSize {
    left.add(right)
  }

  
  static func -(left: CGSize, right: CGSize) -> CGSize {
    left.subtract(right)
  }

  
  static func *(left: CGSize, right: CGFloat) -> CGSize {
    CGSize(width: left.width * right, height: left.height * right)
  }

  
  func scaleThatFits(_ size: CGSize) -> CGFloat {
    CGFloat.minimum(width / size.width, height / size.height)
  }

  
  func add(_ size: CGSize) -> CGSize {
    CGSize(width: width + size.width, height: height + size.height)
  }

  
  func subtract(_ size: CGSize) -> CGSize {
    CGSize(width: width - size.width, height: height - size.height)
  }

  
  func multiply(_ size: CGSize) -> CGSize {
    CGSize(width: width * size.width, height: height * size.height)
  }
}




struct CGLine {

  

  
  init(start: CGPoint, end: CGPoint) {
    self.start = start
    self.end = end
  }

  

  
  var start: CGPoint
  
  var end: CGPoint

  
  var length: CGFloat {
    end.distanceTo(start)
  }

  
  func normalize() -> CGLine {
    let len = length
    guard len > 0 else {
      return self
    }
    let relativeEnd = end - start
    let relativeVector = CGPoint(x: relativeEnd.x / len, y: relativeEnd.y / len)
    let absoluteVector = relativeVector + start
    return CGLine(start: start, end: absoluteVector)
  }

  
  func trimmedToLength(_ toLength: CGFloat) -> CGLine {
    let len = length
    guard len > 0 else {
      return self
    }
    let relativeEnd = end - start
    let relativeVector = CGPoint(x: relativeEnd.x / len, y: relativeEnd.y / len)
    let sizedVector = CGPoint(x: relativeVector.x * toLength, y: relativeVector.y * toLength)
    let absoluteVector = sizedVector + start
    return CGLine(start: start, end: absoluteVector)
  }

  
  func flipped() -> CGLine {
    let relativeEnd = end - start
    let flippedEnd = CGPoint(x: relativeEnd.x * -1, y: relativeEnd.y * -1)
    return CGLine(start: start, end: flippedEnd + start)
  }

  
  func transpose(_ toPoint: CGPoint) -> CGLine {
    let diff = toPoint - start
    let newEnd = end + diff
    return CGLine(start: toPoint, end: newEnd)
  }

}

infix operator +|
infix operator +-

extension CGPoint {

  
  var vectorLength: CGFloat {
    distanceTo(.zero)
  }

  var isZero: Bool {
    x == 0 && y == 0
  }

  
  static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    CGPoint(x: lhs.x / CGFloat(rhs), y: lhs.y / CGFloat(rhs))
  }

  
  static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
  }

  
  static func +(left: CGPoint, right: CGPoint) -> CGPoint {
    left.add(right)
  }

  
  static func -(left: CGPoint, right: CGPoint) -> CGPoint {
    left.subtract(right)
  }

  static func +|(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x, y: left.y + right)
  }

  static func +-(left: CGPoint, right: CGFloat) -> CGPoint {
    CGPoint(x: left.x + right, y: left.y)
  }

  
  func distanceTo(_ a: CGPoint) -> CGFloat {
    let xDist = a.x - x
    let yDist = a.y - y
    return CGFloat(sqrt((xDist * xDist) + (yDist * yDist)))
  }

  func rounded(decimal: CGFloat) -> CGPoint {
    CGPoint(x: round(decimal * x) / decimal, y: round(decimal * y) / decimal)
  }

  func interpolate(
    _ to: CGPoint,
    outTangent: CGPoint,
    inTangent: CGPoint,
    amount: CGFloat,
    maxIterations: Int = 3,
    samples: Int = 20,
    accuracy: CGFloat = 1)
    -> CGPoint
  {
    if amount == 0 {
      return self
    }
    if amount == 1 {
      return to
    }

    if
      colinear(outTangent, inTangent) == true,
      outTangent.colinear(inTangent, to) == true
    {
      return interpolate(to: to, amount: amount)
    }

    let step = 1 / CGFloat(samples)

    var points: [(point: CGPoint, distance: CGFloat)] = [(point: self, distance: 0)]
    var totalLength: CGFloat = 0

    var previousPoint = self
    var previousAmount = CGFloat(0)

    var closestPoint = 0

    while previousAmount < 1 {

      previousAmount = previousAmount + step

      if previousAmount < amount {
        closestPoint = closestPoint + 1
      }

      let newPoint = pointOnPath(to, outTangent: outTangent, inTangent: inTangent, amount: previousAmount)
      let distance = previousPoint.distanceTo(newPoint)
      totalLength = totalLength + distance
      points.append((point: newPoint, distance: totalLength))
      previousPoint = newPoint
    }

    let accurateDistance = amount * totalLength
    var point = points[closestPoint]

    var foundPoint = false

    var pointAmount = CGFloat(closestPoint) * step
    var nextPointAmount: CGFloat = pointAmount + step

    var refineIterations = 0
    while foundPoint == false {
      refineIterations = refineIterations + 1
      
      let nextPoint = points[closestPoint + 1]
      if nextPoint.distance < accurateDistance {
        point = nextPoint
        closestPoint = closestPoint + 1
        pointAmount = CGFloat(closestPoint) * step
        nextPointAmount = pointAmount + step
        if closestPoint == points.count {
          foundPoint = true
        }
        continue
      }
      if accurateDistance < point.distance {
        closestPoint = closestPoint - 1
        if closestPoint < 0 {
          foundPoint = true
          continue
        }
        point = points[closestPoint]
        pointAmount = CGFloat(closestPoint) * step
        nextPointAmount = pointAmount + step
        continue
      }

      
      let pointDiff = nextPoint.distance - point.distance
      let proposedPointAmount = ((accurateDistance - point.distance) / pointDiff)
        .remap(fromLow: 0, fromHigh: 1, toLow: pointAmount, toHigh: nextPointAmount)

      let newPoint = pointOnPath(to, outTangent: outTangent, inTangent: inTangent, amount: proposedPointAmount)
      let newDistance = point.distance + point.point.distanceTo(newPoint)
      pointAmount = proposedPointAmount
      point = (point: newPoint, distance: newDistance)
      if
        accurateDistance - newDistance <= accuracy ||
        newDistance - accurateDistance <= accuracy
      {
        foundPoint = true
      }

      if refineIterations == maxIterations {
        foundPoint = true
      }
    }
    return point.point
  }

  func pointOnPath(_ to: CGPoint, outTangent: CGPoint, inTangent: CGPoint, amount: CGFloat) -> CGPoint {
    let a = interpolate(to: outTangent, amount: amount)
    let b = outTangent.interpolate(to: inTangent, amount: amount)
    let c = inTangent.interpolate(to: to, amount: amount)
    let d = a.interpolate(to: b, amount: amount)
    let e = b.interpolate(to: c, amount: amount)
    let f = d.interpolate(to: e, amount: amount)
    return f
  }

  func colinear(_ a: CGPoint, _ b: CGPoint) -> Bool {
    let area = x * (a.y - b.y) + a.x * (b.y - y) + b.x * (y - a.y);
    let accuracy: CGFloat = 0.05
    if area < accuracy && area > -accuracy {
      return true
    }
    return false
  }

  
  func subtract(_ point: CGPoint) -> CGPoint {
    CGPoint(
      x: x - point.x,
      y: y - point.y)
  }

  
  func add(_ point: CGPoint) -> CGPoint {
    CGPoint(
      x: x + point.x,
      y: y + point.y)
  }
}
