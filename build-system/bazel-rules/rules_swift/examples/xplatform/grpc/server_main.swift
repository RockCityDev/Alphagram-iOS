

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Dispatch
import SwiftGRPC
import examples_xplatform_grpc_echo_proto
import examples_xplatform_grpc_echo_server_services_swift


class EchoProvider: RulesSwift_Examples_Grpc_EchoServiceProvider {

  
  
  
  
  
  
  
  func echo(request: RulesSwift_Examples_Grpc_EchoRequest,
            session: RulesSwift_Examples_Grpc_EchoServiceEchoSession
  ) throws -> RulesSwift_Examples_Grpc_EchoResponse {
    var response = RulesSwift_Examples_Grpc_EchoResponse()
    response.contents = "You sent: \(request.contents)"
    return response
  }
}


let address = "0.0.0.0:9000"
let server = ServiceServer(address: address, serviceProviders: [EchoProvider()])
print("Starting server in \(address)")
server.start()


dispatchMain()
