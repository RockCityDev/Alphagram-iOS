

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import os


struct RawExplicitModulesMetadata: Codable {
  var explicitModules: [RawExplicitModuleBody]

  private enum CodingKeys : String, CodingKey {
    case explicitModules = "explicit_modules"
  }
}


struct RawExplicitModuleBody: Codable {
  
  var path: String
  
  var name: String
}



func getExplicitModuleNames(fromMetadataFile metadataPath: String) throws -> [String] {
  let metadataURL = URL(fileURLWithPath: metadataPath)
  let data = try Data(contentsOf: metadataURL)
  let jsonData = try JSONDecoder().decode(RawExplicitModulesMetadata.self, from: data)
  return jsonData.explicitModules.map { $0.name }
}
