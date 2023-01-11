

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import os

private let fileManager = FileManager.default



func getImplicitModules(moduleCacheURL: URL) -> [String: [URL]] {
  let implicitModules = getModulesInModuleCache(moduleCacheURL)
  return mapModuleNamesToModuleURLs(implicitModules)
}



private func mapModuleNamesToModuleURLs(_ moduleURLs: [URL]) -> [String: [URL]] {
  var moduleNameToURLs: [String: [URL]] = [:]

  for url in moduleURLs {
    if let moduleName = moduleNameForImplicitPrecompiledModule(at: url) {
      var urlsForModule = moduleNameToURLs[moduleName, default: []]
      urlsForModule.append(url)
      moduleNameToURLs[moduleName] = urlsForModule
    }
  }

  return moduleNameToURLs
}



private func getModulesInModuleCache(_ moduleCacheURL: URL) -> [URL] {
  let subdirectories = getDirectoriesInModuleCacheRoot(moduleCacheURL)
  var moduleURLs = [URL]()

  let moduleURLsWriteQueue = DispatchQueue(label: "module-cache-urls")
  let directoryEnumeratingDispatchGroup = DispatchGroup()

  for subdirectory in subdirectories {
    directoryEnumeratingDispatchGroup.enter()

    DispatchQueue.global(qos: .default).async {
      let modulesInSubdirectory = getModulesInModuleCacheSubdirectory(subdirectory)
      moduleURLsWriteQueue.async {
        moduleURLs.append(contentsOf: modulesInSubdirectory)
        directoryEnumeratingDispatchGroup.leave()
      }
    }
  }

  directoryEnumeratingDispatchGroup.wait()
  return moduleURLs
}












private func getDirectoriesInModuleCacheRoot(_ moduleCacheURL: URL) -> [URL] {
  do {
    let contents = try fileManager.contentsOfDirectory(
      at: moduleCacheURL, includingPropertiesForKeys: nil, options: [])
    return contents.filter { $0.hasDirectoryPath }
  } catch {
    os_log(
      "Failed to read contents of module cache root at %@: %@", log: logger, type: .error,
      moduleCacheURL.absoluteString, error.localizedDescription)
    return []
  }
}














private func getModulesInModuleCacheSubdirectory(
  _ directoryURL: URL
) -> [URL] {
  do {
    let contents = try fileManager.contentsOfDirectory(
      at: directoryURL, includingPropertiesForKeys: nil, options: [])
    return contents.filter { !$0.hasDirectoryPath && $0.pathExtension == "pcm" }
  } catch {
    os_log(
      "Failed to read contents of module cache subdirectory at %@: %@", log: logger, type: .error,
      directoryURL.absoluteString, error.localizedDescription)
    return []
  }
}


/// the form "<ModuleName-HashAA>.pcm" e.g. "Foundation-3DFYNEBRQSXST.pcm".
private func moduleNameForImplicitPrecompiledModule(at moduleURL: URL) -> String? {
  let filename = moduleURL.lastPathComponent
  return filename.components(separatedBy: "-").first
}
