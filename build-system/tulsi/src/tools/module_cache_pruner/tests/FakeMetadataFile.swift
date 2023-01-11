

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

@testable import ModuleCachePruner


func createFakeMetadataFile(contents: RawExplicitModulesMetadata) throws -> URL {
  let temporaryFileURL = getTemporaryJSONFileURL()
  let jsonData = try JSONEncoder().encode(contents)
  try jsonData.write(to: temporaryFileURL)
  return temporaryFileURL
}




func createFakeMetadataFile(withExplicitModules modules: [FakeModule]) throws -> URL {
  let fakeMetadataBody = modules.map {
    RawExplicitModuleBody(
      path: $0.explicitFilepath, name: $0.name)
  }
  let fakeMetadata = RawExplicitModulesMetadata(explicitModules: fakeMetadataBody)
  return try createFakeMetadataFile(contents: fakeMetadata)
}
