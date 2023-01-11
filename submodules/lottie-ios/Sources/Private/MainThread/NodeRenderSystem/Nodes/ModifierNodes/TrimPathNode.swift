






import Foundation
import QuartzCore



final class TrimPathProperties: NodePropertyMap, KeypathSearchable {

  

  init(trim: Trim) {
    keypathName = trim.name
    start = NodeProperty(provider: KeyframeInterpolator(keyframes: trim.start.keyframes))
    end = NodeProperty(provider: KeyframeInterpolator(keyframes: trim.end.keyframes))
    offset = NodeProperty(provider: KeyframeInterpolator(keyframes: trim.offset.keyframes))
    type = trim.trimType
    keypathProperties = [
      "Start" : start,
      "End" : end,
      "Offset" : offset,
    ]
    properties = Array(keypathProperties.values)
  }

  

  let keypathProperties: [String: AnyNodeProperty]
  let properties: [AnyNodeProperty]
  let keypathName: String

  let start: NodeProperty<Vector1D>
  let end: NodeProperty<Vector1D>
  let offset: NodeProperty<Vector1D>
  let type: TrimType
}



final class TrimPathNode: AnimatorNode {

  

  init(parentNode: AnimatorNode?, trim: Trim, upstreamPaths: [PathOutputNode]) {
    outputNode = PassThroughOutputNode(parent: parentNode?.outputNode)
    self.parentNode = parentNode
    properties = TrimPathProperties(trim: trim)
    self.upstreamPaths = upstreamPaths
  }

  

  let properties: TrimPathProperties

  let parentNode: AnimatorNode?
  let outputNode: NodeOutput
  var hasLocalUpdates = false
  var hasUpstreamUpdates = false
  var lastUpdateFrame: CGFloat? = nil
  var isEnabled = true

  
  var propertyMap: NodePropertyMap & KeypathSearchable {
    properties
  }

  func forceUpstreamOutputUpdates() -> Bool {
    hasLocalUpdates || hasUpstreamUpdates
  }

  func rebuildOutputs(frame: CGFloat) {
    
    let startValue = properties.start.value.cgFloatValue * 0.01
    let endValue = properties.end.value.cgFloatValue * 0.01
    let start = min(startValue, endValue)
    let end = max(startValue, endValue)

    let offset = properties.offset.value.cgFloatValue.truncatingRemainder(dividingBy: 360) / 360

    
    if start == 0, end == 1 {
      return
    }

    
    if start == end {
      for pathContainer in upstreamPaths {
        pathContainer.removePaths(updateFrame: frame)
      }
      return
    }

    if properties.type == .simultaneously {
      
      for pathContainer in upstreamPaths {
        let pathObjects = pathContainer.removePaths(updateFrame: frame)
        for path in pathObjects {
          
          pathContainer.appendPath(
            path.trim(fromPosition: start, toPosition: end, offset: offset, trimSimultaneously: false),
            updateFrame: frame)
        }
      }
      return
    }

    

    

    
    var startPosition = (start + offset).truncatingRemainder(dividingBy: 1)
    var endPosition = (end + offset).truncatingRemainder(dividingBy: 1)

    if startPosition < 0 {
      startPosition = 1 + startPosition
    }

    if endPosition < 0 {
      endPosition = 1 + endPosition
    }
    if startPosition == 1 {
      startPosition = 0
    }
    if endPosition == 0 {
      endPosition = 1
    }

    
    var totalLength: CGFloat = 0
    upstreamPaths.forEach({ totalLength = totalLength + $0.totalLength })

    
    let startLength = startPosition * totalLength
    let endLength = endPosition * totalLength
    var pathStart: CGFloat = 0

    
    for pathContainer in upstreamPaths {

      let pathEnd = pathStart + pathContainer.totalLength

      if
        !startLength.isInRange(pathStart, pathEnd) &&
        endLength.isInRange(pathStart, pathEnd)
      {
        
        

        let pathCutLength = endLength - pathStart
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {
          let subpathEnd = subpathStart + path.length
          if pathCutLength < subpathEnd {
            
            let cutLength = pathCutLength - subpathStart
            let newPath = path.trim(fromPosition: 0, toPosition: cutLength / path.length, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          } else {
            
            pathContainer.appendPath(path, updateFrame: frame)
          }
          if pathCutLength == subpathEnd {
            
            break
          }
          subpathStart = subpathEnd
        }

      } else if
        !endLength.isInRange(pathStart, pathEnd) &&
        startLength.isInRange(pathStart, pathEnd)
      {
        
        

        
        let pathCutLength = startLength - pathStart
        
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {
          let subpathEnd = subpathStart + path.length

          if subpathStart < pathCutLength, pathCutLength < subpathEnd {
            
            let cutLength = pathCutLength - subpathStart
            let newPath = path.trim(fromPosition: cutLength / path.length, toPosition: 1, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
          } else if pathCutLength <= subpathStart {
            pathContainer.appendPath(path, updateFrame: frame)
          }
          subpathStart = subpathEnd
        }
      } else if
        endLength.isInRange(pathStart, pathEnd) &&
        startLength.isInRange(pathStart, pathEnd)
      {
        
        
        

        
        let startCutLength = startLength - pathStart
        let endCutLength = endLength - pathStart
        
        let subpaths = pathContainer.removePaths(updateFrame: frame)
        var subpathStart: CGFloat = 0
        for path in subpaths {

          let subpathEnd = subpathStart + path.length

          if
            !startCutLength.isInRange(subpathStart, subpathEnd) &&
            !endCutLength.isInRange(subpathStart, subpathEnd)
          {
            
            
            pathContainer.appendPath(path, updateFrame: frame)

          } else if
            startCutLength.isInRange(subpathStart, subpathEnd) &&
            !endCutLength.isInRange(subpathStart, subpathEnd)
          {
            
            
            let cutLength = startCutLength - subpathStart
            let newPath = path.trim(fromPosition: cutLength / path.length, toPosition: 1, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
          } else if
            !startCutLength.isInRange(subpathStart, subpathEnd) &&
            endCutLength.isInRange(subpathStart, subpathEnd)
          {
            
            let cutLength = endCutLength - subpathStart
            let newPath = path.trim(fromPosition: 0, toPosition: cutLength / path.length, offset: 0, trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          } else if
            startCutLength.isInRange(subpathStart, subpathEnd) &&
            endCutLength.isInRange(subpathStart, subpathEnd)
          {
            
            let cutFromLength = startCutLength - subpathStart
            let cutToLength = endCutLength - subpathStart
            let newPath = path.trim(
              fromPosition: cutFromLength / path.length,
              toPosition: cutToLength / path.length,
              offset: 0,
              trimSimultaneously: false)
            pathContainer.appendPath(newPath, updateFrame: frame)
            break
          }

          subpathStart = subpathEnd
        }
      } else if
        (endLength <= pathStart && pathEnd <= startLength) ||
        (startLength <= pathStart && endLength <= pathStart) ||
        (pathEnd <= startLength && pathEnd <= endLength)
      {
        
        pathContainer.removePaths(updateFrame: frame)
      }

      pathStart = pathEnd
    }

  }

  

  fileprivate let upstreamPaths: [PathOutputNode]
}
