

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

class Service: ServiceProtocol {
  func process(message: String, withReply: (String?) -> Void) {
    withReply("You said: '\(message)'")
  }
}

class ServiceDelegate : NSObject, NSXPCListenerDelegate {
  func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
    connection.exportedInterface = NSXPCInterface(with: ServiceProtocol.self)
    connection.exportedObject = Service()
    connection.resume()
    return true
  }
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()
listener.delegate = delegate;
listener.resume()
