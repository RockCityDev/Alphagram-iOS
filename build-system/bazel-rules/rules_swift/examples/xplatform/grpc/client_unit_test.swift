

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest
import examples_xplatform_grpc_echo_client_services_swift
import examples_xplatform_grpc_echo_proto

@testable import examples_xplatform_grpc_echo_client_test_stubs_swift

class ClientUnitTest {

  func testSynchronousCall() throws {
    let client: RulesSwift_Examples_Grpc_EchoServiceService = {
      let stub = RulesSwift_Examples_Grpc_EchoServiceServiceTestStub()
      stub.echoResponses.append(RulesSwift_Examples_Grpc_EchoResponse.with { response in
        response.contents = "Hello"
      })
      return stub
   }()
   let response = try client.echo(RulesSwift_Examples_Grpc_EchoRequest())
   XCTAssertEqual(response.contents, "Hello")
  }
}
