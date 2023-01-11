






import CoreGraphics
import Foundation








struct PathElement {

  

  
  init(vertex: CurveVertex) {
    length = 0
    self.vertex = vertex
  }

  
  private init(length: CGFloat, vertex: CurveVertex) {
    self.length = length
    self.vertex = vertex
  }

  

  
  let length: CGFloat

  
  let vertex: CurveVertex

  
  func pathElementTo(_ toVertex: CurveVertex) -> PathElement {
    PathElement(length: vertex.distanceTo(toVertex), vertex: toVertex)
  }

  func updateVertex(newVertex: CurveVertex) -> PathElement {
    PathElement(length: length, vertex: newVertex)
  }

  
  func splitElementAtPosition(fromElement: PathElement, atLength: CGFloat) ->
    (leftSpan: (start: PathElement, end: PathElement), rightSpan: (start: PathElement, end: PathElement))
  {
    
    let trimResults = fromElement.vertex.trimCurve(toVertex: vertex, atLength: atLength, curveLength: length, maxSamples: 3)

    
    let spanAStart = PathElement(
      length: fromElement.length,
      vertex: CurveVertex(
        point: fromElement.vertex.point,
        inTangent: fromElement.vertex.inTangent,
        outTangent: trimResults.start.outTangent))
    
    let spanAEnd = spanAStart.pathElementTo(trimResults.trimPoint)

    let spanBStart = PathElement(vertex: trimResults.trimPoint)
    let spanBEnd = spanBStart.pathElementTo(trimResults.end)
    return (
      leftSpan: (start: spanAStart, end: spanAEnd),
      rightSpan: (start: spanBStart, end: spanBEnd))
  }

}
