






import CoreGraphics
import Foundation

extension Color {

  

  
  init(h: Double, s: Double, v: Double, a: Double) {

    let i = floor(h * 6)
    let f = h * 6 - i
    let p = v * (1 - s);
    let q = v * (1 - f * s)
    let t = v * (1 - (1 - f) * s)

    switch i.truncatingRemainder(dividingBy: 6) {
    case 0:
      r = v
      g = t
      b = p
    case 1:
      r = q
      g = v
      b = p
    case 2:
      r = p
      g = v
      b = t
    case 3:
      r = p
      g = q
      b = v
    case 4:
      r = t
      g = p
      b = v
    case 5:
      r = v
      g = p
      b = q
    default:
      r = 0
      g = 0
      b = 0
    }
    self.a = a
  }

  init(y: Double, u: Double, v: Double, a: Double) {
    
    r = y + 1.403 * v
    g = y - 0.344 * u
    b = y + 1.770 * u
    self.a = a
  }

  

  
  var hsva: (h: Double, s: Double, v: Double, a: Double) {
    let maxValue = max(r, g, b)
    let minValue = min(r, g, b)

    var h: Double, s: Double, v: Double = maxValue

    let d = maxValue - minValue
    s = maxValue == 0 ? 0 : d / maxValue;

    if maxValue == minValue {
      h = 0; 
    } else {
      switch maxValue {
      case r: h = (g - b) / d + (g < b ? 6 : 0)
      case g: h = (b - r) / d + 2
      case b: h = (r - g) / d + 4
      default: h = maxValue
      }
      h = h / 6
    }
    return (h: h, s: s, v: v, a: a)
  }

  var yuv: (y: Double, u: Double, v: Double, a: Double) {
    
    let y = 0.299 * r + 0.587 * g + 0.114 * b
    let u = -0.14713 * r - 0.28886 * g + 0.436 * b
    let v = 0.615 * r - 0.51499 * g - 0.10001 * b
    return (y: y, u: u, v: v, a: a)
  }

}



extension CurveVertex: Interpolatable {
  func interpolate(to: CurveVertex, amount: CGFloat) -> CurveVertex {
    CurveVertex(
      point: point.interpolate(to: to.point, amount: amount),
      inTangent: inTangent.interpolate(to: to.inTangent, amount: amount),
      outTangent: outTangent.interpolate(to: to.outTangent, amount: amount))
  }
}



extension BezierPath: Interpolatable {
  func interpolate(to: BezierPath, amount: CGFloat) -> BezierPath {
    var newPath = BezierPath()
    for i in 0..<min(elements.count, to.elements.count) {
      let fromVertex = elements[i].vertex
      let toVertex = to.elements[i].vertex
      newPath.addVertex(fromVertex.interpolate(to: toVertex, amount: amount))
    }
    return newPath
  }
}



extension TextDocument: Interpolatable {
  func interpolate(to: TextDocument, amount: CGFloat) -> TextDocument {
    if amount == 1 {
      return to
    }
    return self
  }
}
