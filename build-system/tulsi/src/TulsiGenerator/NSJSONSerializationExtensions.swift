

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


extension JSONSerialization {
  enum EncodingError: Error {
    
    case stringUTF8EncodingError
    
    case objectUTF8EncodingError
  }

  class func tulsi_newlineTerminatedUnescapedData(
    jsonObject: Any,
    options: JSONSerialization.WritingOptions
  ) throws -> NSMutableData {
    let content = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
    guard var mutableString = String(data: content, encoding: String.Encoding.utf8) else {
      throw EncodingError.objectUTF8EncodingError
    }
    mutableString.append("\n")
    mutableString = mutableString.replacingOccurrences(of: "\\/", with: "/")
    guard let output = mutableString.data(using: String.Encoding.utf8) else {
      throw EncodingError.stringUTF8EncodingError
    }
    return NSMutableData(data: output)
  }
}
