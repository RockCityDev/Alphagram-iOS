

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

@objc(ServiceProtocol) protocol ServiceProtocol {
  func process(message: String, withReply: @escaping (String?) -> Void)
}
