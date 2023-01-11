






import Foundation
import QuartzCore

extension KeypathSearchable {

  func animatorNodes(for keyPath: AnimationKeypath) -> [AnimatorNode]? {
    
    guard let currentKey = keyPath.currentKey else { return nil }

    
    guard let nextKeypath = keyPath.popKey(keypathName) else {
      
      if
        let node = self as? AnimatorNode,
        currentKey.equalsKeypath(keypathName)
      {
        
        return [node]
      }
      
      return nil
    }

    var results: [AnimatorNode] = []

    if
      let node = self as? AnimatorNode,
      nextKeypath.currentKey == nil
    {
      
      results.append(node)
    }

    for childNode in childKeypaths {
      
      if let foundNodes = childNode.animatorNodes(for: nextKeypath) {
        results.append(contentsOf: foundNodes)
      }

      
      if
        currentKey.keyPathType == .fuzzyWildcard,
        let nextKeypath = keyPath.nextKeypath,
        nextKeypath.equalsKeypath(childNode.keypathName),
        let foundNodes = childNode.animatorNodes(for: keyPath)
      {
        results.append(contentsOf: foundNodes)
      }
    }

    guard results.count > 0 else {
      return nil
    }

    return results
  }

  func nodeProperties(for keyPath: AnimationKeypath) -> [AnyNodeProperty]? {
    guard let nextKeypath = keyPath.popKey(keypathName) else {
      
      return nil
    }

    
    var results: [AnyNodeProperty] = []

    
    if
      let propertyKey = nextKeypath.propertyKey,
      let property = keypathProperties[propertyKey]
    {
      
      results.append(property)
    }

    if nextKeypath.nextKeypath != nil {
      
      for child in childKeypaths {
        if let childProperties = child.nodeProperties(for: nextKeypath) {
          results.append(contentsOf: childProperties)
        }
      }
    }

    guard results.count > 0 else {
      return nil
    }

    return results
  }

  func layer(for keyPath: AnimationKeypath) -> CALayer? {
    if keyPath.nextKeypath == nil, let layerKey = keyPath.currentKey, layerKey.equalsKeypath(keypathName) {
      
      return keypathLayer
    }
    guard let nextKeypath = keyPath.popKey(keypathName) else {
      
      return nil
    }

    
    for child in childKeypaths {
      if let layer = child.layer(for: nextKeypath) {
        return layer
      }
    }
    return nil
  }
    
    func allLayers(for keyPath: AnimationKeypath) -> [CALayer] {
        if keyPath.nextKeypath == nil, let layerKey = keyPath.currentKey, layerKey.equalsKeypath(keypathName) {
            
            
            if let keypathLayer = self.keypathLayer {
                return [keypathLayer]
            } else {
                return []
            }
        }
        guard let nextKeypath = keyPath.popKey(keypathName) else {
            
            return []
        }
        
        
        var foundSublayers: [CALayer] = []
        for child in childKeypaths {
            foundSublayers.append(contentsOf: child.allLayers(for: nextKeypath))
        }
        return foundSublayers
    }

  func logKeypaths(for keyPath: AnimationKeypath?) {
    let newKeypath: AnimationKeypath
    if let previousKeypath = keyPath {
      newKeypath = previousKeypath.appendingKey(keypathName)
    } else {
      newKeypath = AnimationKeypath(keys: [keypathName])
    }
    print(newKeypath.fullPath)
    for key in keypathProperties.keys {
      print(newKeypath.appendingKey(key).fullPath)
    }
    for child in childKeypaths {
      child.logKeypaths(for: newKeypath)
    }
  }
    
  func allKeypaths(for keyPath: AnimationKeypath?, predicate: (AnimationKeypath) -> Bool) -> [String] {
      var result: [String] = []
      let newKeypath: AnimationKeypath
      if let previousKeypath = keyPath {
        newKeypath = previousKeypath.appendingKey(keypathName)
      } else {
        newKeypath = AnimationKeypath(keys: [keypathName])
      }
      if predicate(newKeypath) {
          result.append(newKeypath.fullPath)
      }
      for key in keypathProperties.keys {
          let subKey = newKeypath.appendingKey(key)
          if predicate(subKey) {
              result.append(subKey.fullPath)
          }
      }
      for child in childKeypaths {
        result.append(contentsOf: child.allKeypaths(for: newKeypath, predicate: predicate))
      }
      return result
  }
}

extension AnimationKeypath {
  var currentKey: String? {
    keys.first
  }

  var nextKeypath: String? {
    guard keys.count > 1 else {
      return nil
    }
    return keys[1]
  }

  var propertyKey: String? {
    if nextKeypath == nil {
      
      return currentKey
    }
    if keys.count == 2, currentKey?.keyPathType == .fuzzyWildcard {
      
      return nextKeypath
    }
    return nil
  }

  var fullPath: String {
    keys.joined(separator: ".")
  }

  
  func popKey(_ keyname: String) -> AnimationKeypath? {
    guard
      let currentKey = currentKey,
      currentKey.equalsKeypath(keyname),
      keys.count > 1 else
    {
      
      return nil
    }

    
    let newKeys: [String]

    if currentKey.keyPathType == .fuzzyWildcard {
      
      if
        let nextKeypath = nextKeypath,
        nextKeypath.equalsKeypath(keyname)
      {
        
        var oldKeys = keys
        oldKeys.remove(at: 0)
        oldKeys.remove(at: 0)
        newKeys = oldKeys
      } else {
        newKeys = keys
      }
    } else {
      var oldKeys = keys
      oldKeys.remove(at: 0)
      newKeys = oldKeys
    }

    return AnimationKeypath(keys: newKeys)
  }

  func appendingKey(_ key: String) -> AnimationKeypath {
    var newKeys = keys
    newKeys.append(key)
    return AnimationKeypath(keys: newKeys)
  }
}

extension String {
  var keyPathType: KeyType {
    switch self {
    case "*":
      return .wildcard
    case "**":
      return .fuzzyWildcard
    default:
      return .specific
    }
  }

  func equalsKeypath(_ keyname: String) -> Bool {
    if keyPathType == .wildcard || keyPathType == .fuzzyWildcard {
      return true
    }
    if self == keyname {
      return true
    }
    if let index = firstIndex(of: "*") {
      
      let prefix = String(self.prefix(upTo: index))
      let suffix = String(self.suffix(from: self.index(after: index)))

      if prefix.count > 0 {
        
        if keyname.count < prefix.count {
          return false
        }
        let testPrefix = String(keyname.prefix(upTo: keyname.index(keyname.startIndex, offsetBy: prefix.count)))
        if testPrefix != prefix {
          
          return false
        }
      }
      if suffix.count > 0 {
        
        if keyname.count < suffix.count {
          
          return false
        }
        let index = keyname.index(keyname.endIndex, offsetBy: -suffix.count)
        let testSuffix = String(keyname.suffix(from: index))
        if testSuffix != suffix {
          return false
        }
      }
      return true
    }
    return false
  }
}



enum KeyType {
  case specific
  case wildcard
  case fuzzyWildcard
}
