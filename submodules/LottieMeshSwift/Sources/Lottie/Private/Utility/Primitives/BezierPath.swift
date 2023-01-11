






import Foundation
import CoreGraphics


struct BezierPath {
  
  
  fileprivate(set) var elements: [PathElement]
  
  
  fileprivate(set) var closed: Bool
  
  
  fileprivate(set) var length: CGFloat
  
  
  init(startPoint: CurveVertex) {
    self.elements = [PathElement(vertex: startPoint)]
    self.length = 0
    self.closed = false
  }
  
  init() {
    self.elements = []
    self.length = 0
    self.closed = false
  }
  
  mutating func moveToStartPoint(_ vertex: CurveVertex) {
    self.elements = [PathElement(vertex: vertex)]
    self.length = 0
  }
  
  mutating func addVertex(_ vertex: CurveVertex) {
    guard let previous = elements.last else {
      addElement(PathElement(vertex: vertex))
      return
    }
    addElement(previous.pathElementTo(vertex))
  }
  
  mutating func addCurve(toPoint: CGPoint, outTangent: CGPoint, inTangent: CGPoint) {
    guard let previous = elements.last else { return }
    let newVertex = CurveVertex(inTangent, toPoint, toPoint)
    updateVertex(CurveVertex(previous.vertex.inTangent, previous.vertex.point, outTangent), atIndex: elements.endIndex - 1, remeasure: false)
    addVertex(newVertex)
  }
  
  mutating func addLine(toPoint: CGPoint) {
    guard let previous = elements.last else { return }
    let newVertex = CurveVertex(point: toPoint, inTangentRelative: .zero, outTangentRelative: .zero)
    updateVertex(CurveVertex(previous.vertex.inTangent, previous.vertex.point, previous.vertex.point), atIndex: elements.endIndex - 1, remeasure: false)
    addVertex(newVertex)
  }
  
  mutating func close() {
    self.closed = true
  }
  
  mutating func addElement(_ pathElement: PathElement) {
    elements.append(pathElement)
    length = length + pathElement.length
  }
  
  mutating func updateVertex(_ vertex: CurveVertex, atIndex: Int, remeasure: Bool) {
    if remeasure {
      var newElement: PathElement
      if atIndex > 0 {
        let previousElement = elements[atIndex-1]
        newElement = previousElement.pathElementTo(vertex)
      } else {
        newElement = PathElement(vertex: vertex)
      }
      elements[atIndex] = newElement
      
      if atIndex + 1 < elements.count{
        let nextElement = elements[atIndex + 1]
        elements[atIndex + 1] = newElement.pathElementTo(nextElement.vertex)
      }
      
    } else {
      let oldElement = elements[atIndex]
      elements[atIndex] = oldElement.updateVertex(newVertex: vertex)
    }
  }
  
  
  func trim(fromLength: CGFloat, toLength: CGFloat, offsetLength: CGFloat) -> [BezierPath] {
    guard elements.count > 1 else {
      return []
    }
    
    if fromLength == toLength {
      return []
    }
    
    
    var start = (fromLength+offsetLength).truncatingRemainder(dividingBy: length)
    var end =  (toLength+offsetLength).truncatingRemainder(dividingBy: length)
    
    if start < 0 {
      start = length + start
    }
    
    if end < 0 {
      end = length + end
    }
    
    if start == length {
      start = 0
    }
    if end == 0 {
      end = length
    }
    
    if start == 0 && end == length ||
      start == end ||
      start == length && end == 0 {
      
      return [self]
    }
    
    if start > end {
      
      return trimPathAtLengths(positions: [(start: 0, end: end), (start: start, end: length)])
    }
    
    return trimPathAtLengths(positions: [(start: start, end: end)])
  }
  
  
  
  
  fileprivate func trimPathAtLengths(positions: [(start: CGFloat, end: CGFloat)]) -> [BezierPath] {
    guard positions.count > 0 else {
      return []
    }
    var remainingPositions = positions
    
    var trim = remainingPositions.remove(at: 0)

    var paths = [BezierPath]()
    
    var runningLength: CGFloat = 0
    var finishedTrimming: Bool = false
    var pathElements = elements
    
    var currentPath = BezierPath()
    var i: Int = 0
    
    while !finishedTrimming {
      if pathElements.count <= i {
        
        paths.append(currentPath)
        finishedTrimming = true
        continue
      }
      
      
      let element = pathElements[i]
      
      
      let newLength = runningLength + element.length
      
      if newLength < trim.start {
        
        runningLength = newLength
        i = i + 1
        
        continue
      }
      
      if newLength == trim.start {
        
        
        currentPath.moveToStartPoint(element.vertex)
        runningLength = newLength
        i = i + 1
        
        continue
      }
      
      if runningLength < trim.start, trim.start < newLength, currentPath.elements.count == 0 {
        
        
        let previousElement = pathElements[i-1]
        
        let trimLength = trim.start - runningLength
        let trimResults = element.splitElementAtPosition(fromElement: previousElement, atLength: trimLength)
        
        currentPath.moveToStartPoint(trimResults.rightSpan.start.vertex)

        pathElements[i] = trimResults.rightSpan.end
        pathElements[i-1] = trimResults.rightSpan.start
        runningLength = runningLength + trimResults.leftSpan.end.length
        
        continue
      }
      
      if trim.start < newLength, newLength < trim.end {
        
        currentPath.addElement(element)
        runningLength = newLength
        i = i + 1
        continue
      }
      
      if newLength == trim.end {
        
        
        currentPath.addElement(element)
        
        runningLength = newLength
        i = i + 1
        
        
      }
      
      if runningLength < trim.end, trim.end < newLength {
        
        
        let previousElement = pathElements[i-1]
        
        let trimLength = trim.end - runningLength
        let trimResults = element.splitElementAtPosition(fromElement: previousElement, atLength: trimLength)
        
        
        currentPath.updateVertex(trimResults.leftSpan.start.vertex, atIndex: currentPath.elements.count - 1, remeasure: false)
        currentPath.addElement(trimResults.leftSpan.end)
        
        pathElements[i] = trimResults.rightSpan.end
        pathElements[i-1] = trimResults.rightSpan.start
        runningLength = runningLength + trimResults.leftSpan.end.length
        
        
        
        
      }
      
      paths.append(currentPath)
      currentPath = BezierPath()
      if remainingPositions.count > 0 {
        trim = remainingPositions.remove(at: 0)
      } else {
        finishedTrimming = true
      }
    }
    return paths
  }
  
}

extension BezierPath: Codable {
  
  
  
  enum CodingKeys : String, CodingKey {
    case closed = "c"
    case inPoints = "i"
    case outPoints = "o"
    case vertices = "v"
  }
  
  init(from decoder: Decoder) throws {
    let container: KeyedDecodingContainer<BezierPath.CodingKeys>
    
    if let keyedContainer = try? decoder.container(keyedBy: BezierPath.CodingKeys.self) {
      container = keyedContainer
    } else {
      var unkeyedContainer = try decoder.unkeyedContainer()
      container = try unkeyedContainer.nestedContainer(keyedBy: BezierPath.CodingKeys.self)
    }
    
    self.closed = try container.decodeIfPresent(Bool.self, forKey: .closed) ?? true
    
    var vertexContainer = try container.nestedUnkeyedContainer(forKey: .vertices)
    var inPointsContainer = try container.nestedUnkeyedContainer(forKey: .inPoints)
    var outPointsContainer = try container.nestedUnkeyedContainer(forKey: .outPoints)
    
    guard vertexContainer.count == inPointsContainer.count, inPointsContainer.count == outPointsContainer.count else {
      
      
      throw DecodingError.dataCorruptedError(forKey: CodingKeys.vertices,
                                             in: container,
                                             debugDescription: "Vertex data does not match In Tangents and Out Tangents")
    }
    
    guard let count = vertexContainer.count, count > 0 else {
      self.length = 0
      self.elements = []
      return
    }
    
    var decodedElements = [PathElement]()
    
    
    let firstVertex = CurveVertex(point: try vertexContainer.decode(CGPoint.self),
                                  inTangentRelative: try inPointsContainer.decode(CGPoint.self),
                                  outTangentRelative: try outPointsContainer.decode(CGPoint.self))
    var previousElement = PathElement(vertex: firstVertex)
    decodedElements.append(previousElement)
    
    var totalLength: CGFloat = 0
    while !vertexContainer.isAtEnd {
      
      let vertex = CurveVertex(point: try vertexContainer.decode(CGPoint.self),
                               inTangentRelative: try inPointsContainer.decode(CGPoint.self),
                               outTangentRelative: try outPointsContainer.decode(CGPoint.self))
      let pathElement = previousElement.pathElementTo(vertex)
      decodedElements.append(pathElement)
      previousElement = pathElement
      totalLength = totalLength + pathElement.length
    }
    if closed {
      let closeElement = previousElement.pathElementTo(firstVertex)
      decodedElements.append(closeElement)
      totalLength = totalLength + closeElement.length
    }
    self.length = totalLength
    self.elements = decodedElements
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: BezierPath.CodingKeys.self)
    try container.encode(closed, forKey: .closed)
    
    var vertexContainer = container.nestedUnkeyedContainer(forKey: .vertices)
    var inPointsContainer = container.nestedUnkeyedContainer(forKey: .inPoints)
    var outPointsContainer = container.nestedUnkeyedContainer(forKey: .outPoints)
    
    
    let finalIndex = closed ? self.elements.endIndex - 1 : self.elements.endIndex
    for i in 0..<finalIndex {
      let element = elements[i]
      try vertexContainer.encode(element.vertex.point)
      try inPointsContainer.encode(element.vertex.inTangentRelative)
      try outPointsContainer.encode(element.vertex.outTangentRelative)
    }
    
  }
}

extension BezierPath {
  
  func cgPath() -> CGPath {
    let cgPath = CGMutablePath()
    
    var previousElement: PathElement?
    for element in elements {
      if let previous = previousElement {
        if previous.vertex.outTangentRelative.isZero && element.vertex.inTangentRelative.isZero {
          cgPath.addLine(to: element.vertex.point)
        } else {
            
          cgPath.addCurve(to: element.vertex.point, control1: previous.vertex.outTangent, control2: element.vertex.inTangent)
        }
      } else {
        cgPath.move(to: element.vertex.point)
      }
      previousElement = element
    }
    if self.closed {
      cgPath.closeSubpath()
    }
    return cgPath
  }
  
}
