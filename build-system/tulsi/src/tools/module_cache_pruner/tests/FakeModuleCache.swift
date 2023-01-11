

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


func createFakeModuleCache(with contents: DirectoryStructure) -> URL? {
  guard let temporaryDirectory = createTemporaryDirectory() else {
    return nil
  }

  do {
    try createDirectoryStructure(temporaryDirectory, withContents: contents)
  } catch {
    try? FileManager.default.removeItem(at: temporaryDirectory)
    return nil
  }
  return temporaryDirectory
}




func createFakeModuleCache(
  withSwiftModules swiftModules: [FakeModule],
  andClangModules clangModulesByDirectory: [String: [FakeModule]]
) -> URL? {
  var directories = [String: DirectoryStructure]()
  for (directory, clangModules) in clangModulesByDirectory {
    directories[directory] = DirectoryStructure(files: clangModules.map { $0.implicitFilename })
  }
  let files = swiftModules.map { $0.swiftName }

  let contents = DirectoryStructure(files: files, directories: directories)
  return createFakeModuleCache(with: contents)
}
