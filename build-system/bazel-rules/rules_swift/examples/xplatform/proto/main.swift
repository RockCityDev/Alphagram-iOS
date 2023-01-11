

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import SwiftProtobuf
import examples_xplatform_proto_example_proto

let person = RulesSwift_Examples_Person.with {
  $0.name = "Firstname Lastname"
  $0.age = 30
}

let data = try! person.serializedData()
print(Array(data))

let server = RulesSwift_Examples_Server.with {
  $0.name = "My Server"
  $0.api.name = "My API"
  let option = Google_Protobuf_Option.with {
    $0.name = "Person Option"
    if let value = try? Google_Protobuf_Any(message: person) {
      $0.value = value
    }
  }
  $0.api.options.append(option)
}

let data2 = try! server.serializedData()
print(Array(data2))
