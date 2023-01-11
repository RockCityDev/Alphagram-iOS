

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

private let fileManager = FileManager.default

struct DirectoryStructure {
  var files: [String]?
  var directories: [String: DirectoryStructure]?
}



func createDirectoryStructure(_ directory: URL, withContents contents: DirectoryStructure) throws {
  if let files = contents.files {
    for filename in files {
      let filepath = directory.appendingPathComponent(filename)
      try "".write(to: filepath, atomically: true, encoding: .utf8)
    }
  }

  if let directories = contents.directories {
    for (dirname, contents) in directories {
      let subdirectory = directory.appendingPathComponent(dirname)
      try fileManager.createDirectory(at: subdirectory, withIntermediateDirectories: true)
      try createDirectoryStructure(subdirectory, withContents: contents)
    }
  }
}


func createTemporaryDirectory() -> URL? {
  let osTemporaryDirectory = URL(
    fileURLWithPath: NSTemporaryDirectory(),
    isDirectory: true)

  guard
    let temporaryDirectory = try? fileManager.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: osTemporaryDirectory,
      create: true)
  else {
    return nil
  }

  
  
  
  
  guard let temporaryDirectoryRealPath = realpath(temporaryDirectory.path, nil) else {
    return nil
  }

  return URL(fileURLWithPath: String(cString: temporaryDirectoryRealPath), isDirectory: true)
}



func getTemporaryJSONFileURL() -> URL {
  let temporaryDirectoryURL = URL(
    fileURLWithPath: NSTemporaryDirectory(),
    isDirectory: true)
  let temporaryFilename = ProcessInfo().globallyUniqueString
  return temporaryDirectoryURL.appendingPathComponent("\(temporaryFilename).json")
}



func getDirectoryContentsWithRelativePaths(directory: URL) -> Set<String> {
  
  
  
  
  guard let results = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) else {
    return []
  }

  let directoryPath = directory.path
  var relativeResults = Set<String>()
  for result in results {
    if let resultUrl = result as? URL {
      let resultPath = resultUrl.path
      let path =
        resultPath.hasPrefix(directoryPath)
        ? String(resultPath.dropFirst(directoryPath.count + 1)) : resultPath
      relativeResults.insert(path)
    }
  }
  return relativeResults
}
