






import CoreGraphics
import Foundation


struct CurveVertex {

  

  
  init(_ inTangent: CGPoint, _ point: CGPoint, _ outTangent: CGPoint) {
    self.point = point
    self.inTangent = inTangent
    self.outTangent = outTangent
  }

  
  init(point: CGPoint, inTangentRelative: CGPoint, outTangentRelative: CGPoint) {
    self.point = point
    inTangent = point.add(inTangentRelative)
    outTangent = point.add(outTangentRelative)
  }

  
  init(point: CGPoint, inTangent: CGPoint, outTangent: CGPoint) {
    self.point = point
    self.inTangent = inTangent
    self.outTangent = outTangent
  }

  

  let point: CGPoint

  let inTangent: CGPoint
  let outTangent: CGPoint

  var inTangentRelative: CGPoint {
    inTangent.subtract(point)
  }

  var outTangentRelative: CGPoint {
    outTangent.subtract(point)
  }

  func reversed() -> CurveVertex {
    CurveVertex(point: point, inTangent: outTangent, outTangent: inTangent)
  }

  func translated(_ translation: CGPoint) -> CurveVertex {
    CurveVertex(point: point + translation, inTangent: inTangent + translation, outTangent: outTangent + translation)
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  func splitCurve(toVertex: CurveVertex, position: CGFloat) ->
    (start: CurveVertex, trimPoint: CurveVertex, end: CurveVertex)
  {

    
    if position <= 0 {
      return (
        start: CurveVertex(point: point, inTangentRelative: inTangentRelative, outTangentRelative: .zero),
        trimPoint: CurveVertex(point: point, inTangentRelative: .zero, outTangentRelative: outTangentRelative),
        end: toVertex)
    }

    
    if position >= 1 {
      return (
        start: self,
        trimPoint: CurveVertex(
          point: toVertex.point,
          inTangentRelative: toVertex.inTangentRelative,
          outTangentRelative: .zero),
        end: CurveVertex(
          point: toVertex.point,
          inTangentRelative: .zero,
          outTangentRelative: toVertex.outTangentRelative))
    }

    if outTangentRelative.isZero && toVertex.inTangentRelative.isZero {
      
      let trimPoint = point.interpolate(to: toVertex.point, amount: position)
      return (
        start: self,
        trimPoint: CurveVertex(point: trimPoint, inTangentRelative: .zero, outTangentRelative: .zero),
        end: toVertex)
    }
    
    
    
    
    let a = point.interpolate(to: outTangent, amount: position)
    let b = outTangent.interpolate(to: toVertex.inTangent, amount: position)
    let c = toVertex.inTangent.interpolate(to: toVertex.point, amount: position)
    let d = a.interpolate(to: b, amount: position)
    let e = b.interpolate(to: c, amount: position)
    let f = d.interpolate(to: e, amount: position)
    return (
      start: CurveVertex(point: point, inTangent: inTangent, outTangent: a),
      trimPoint: CurveVertex(point: f, inTangent: d, outTangent: e),
      end: CurveVertex(point: toVertex.point, inTangent: c, outTangent: toVertex.outTangent))
  }

  
  
  
  
  
  
  
  
  
  
  
  func trimCurve(toVertex: CurveVertex, atLength: CGFloat, curveLength: CGFloat, maxSamples: Int, accuracy: CGFloat = 1) ->
    (start: CurveVertex, trimPoint: CurveVertex, end: CurveVertex)
  {
    var currentPosition = atLength / curveLength
    var results = splitCurve(toVertex: toVertex, position: currentPosition)

    if maxSamples == 0 {
      return results
    }

    for _ in 1...maxSamples {
      let length = results.start.distanceTo(results.trimPoint)
      let lengthDiff = atLength - length
      
      if lengthDiff < accuracy {
        return results
      }
      let diffPosition = max(min((currentPosition / length) * lengthDiff, currentPosition * 0.5), currentPosition * -0.5)
      currentPosition = diffPosition + currentPosition
      results = splitCurve(toVertex: toVertex, position: currentPosition)
    }
    return results
  }

  
  
  
  
  
  func distanceTo(_ toVertex: CurveVertex, sampleCount: Int = 25) -> CGFloat {

    if outTangentRelative.isZero && toVertex.inTangentRelative.isZero {
      
      return point.distanceTo(toVertex.point)
    }

    var distance: CGFloat = 0

    var previousPoint = point
    for i in 0..<sampleCount {
      let pointOnCurve = splitCurve(toVertex: toVertex, position: CGFloat(i) / CGFloat(sampleCount)).trimPoint
      distance = distance + previousPoint.distanceTo(pointOnCurve.point)
      previousPoint = pointOnCurve.point
    }
    distance = distance + previousPoint.distanceTo(toVertex.point)
    return distance
  }
}
