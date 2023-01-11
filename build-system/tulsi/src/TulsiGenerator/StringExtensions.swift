

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

extension String {
  
  
  
  public var escapingForShell: String {
    guard rangeOfCharacter(from: .whitespaces) != nil || contains("'") || contains("$") else {
      return self
    }
    let escapedString = replacingOccurrences(of: "'", with: "'\\''")
    return "'\(escapedString)'"
  }
}
