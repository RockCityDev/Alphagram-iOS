

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import SwiftProtobuf
import examples_xplatform_grpc_echo_proto
import examples_xplatform_grpc_echo_client_services_swift


let client = RulesSwift_Examples_Grpc_EchoServiceServiceClient(address: "0.0.0.0:9000",
                                                               secure: false)


var request = RulesSwift_Examples_Grpc_EchoRequest()
request.contents = "Hello, world!"
let timestamp = Google_Protobuf_Timestamp(date: Date())
request.extra = try! Google_Protobuf_Any(message: timestamp)


let response = try client.echo(request)
print(response.contents)
