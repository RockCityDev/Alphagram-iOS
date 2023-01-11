

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


extension URL {
  public func relativePathTo(_ target: URL) -> String? {
    guard self.isFileURL && target.isFileURL else {
      return nil
    }

    let rootComponents = pathComponents
    let targetComponents = target.pathComponents

    if target == self {
      return ""
    }

    let zippedComponents = zip(rootComponents, targetComponents)
    var numCommonComponents = 0
    for (a, b) in zippedComponents {
      if a != b { break }
      numCommonComponents += 1
    }

    
    var relativePath = [String](repeating: "..",
                                count: rootComponents.count - numCommonComponents)

    
    relativePath += targetComponents.suffix(targetComponents.count - numCommonComponents)

    return relativePath.joined(separator: "/")
  }
}
