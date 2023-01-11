

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



protocol QueuedLogging {
  
  func logQueuedInfoMessages()

  
  var hasQueuedInfoMessages: Bool { get }
}
