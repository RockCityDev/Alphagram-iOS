

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import XCTest

@testable import ModuleCachePruner



func assertSetsEqual<T>(_ a: Set<T>, _ b: Set<T>) {
  if a != b {
    XCTFail(
      """
      Set A=\(a) is not equal to Set B=\(b).
      Set A - B = \(a.subtracting(b)).
      Set B - A = \(b.subtracting(a)).
      """)
  }
}

enum TestSetupError: Error {
  case noMetadataFile(msg: String)
  case noModuleCache(msg: String)
}

func createFakes(
  metadataFileWithExplicitModules explicitModules: [FakeModule],
  moduleCacheDirectoryWith moduleCache: (
    swiftModules: [FakeModule], clangModules: [String: [FakeModule]]
  )
) throws -> (metadataFile: URL, moduleCache: URL) {
  var fakeMetadataFile: URL
  do {
    fakeMetadataFile = try createFakeMetadataFile(withExplicitModules: explicitModules)
  } catch {
    throw TestSetupError.noMetadataFile(
      msg: "Failed to create required fake metadata file: \(error)")
  }

  guard
    let fakeModuleCache = createFakeModuleCache(
      withSwiftModules: moduleCache.swiftModules,
      andClangModules: moduleCache.clangModules)
  else {
    throw TestSetupError.noModuleCache(
      msg: "Failed to create fake module cache required for test.")
  }

  return (fakeMetadataFile, fakeModuleCache)
}

class ModuleCachePrunerTests: XCTestCase {
  let modules = FakeModules()
  var fakeMetadataFile: URL?
  var fakeModuleCacheURL: URL?

  private let directoryHash1 = "ABCDEFGH"
  private let directoryHash2 = "12345678"

  override func tearDown() {
    if let fakeMetadataFile = fakeMetadataFile {
      try? FileManager.default.removeItem(at: fakeMetadataFile)
    }
    if let moduleCacheURL = fakeModuleCacheURL {
      try? FileManager.default.removeItem(at: moduleCacheURL)
    }
  }

  private func implicitModuleCacheURLs(
    _ moduleCacheURL: URL, forModulesInDirectories modulesByDirectory: [String: [FakeModule]]
  ) -> Set<URL> {
    var result = Set<URL>()
    for (subdirectoryName, modules) in modulesByDirectory {
      let subdirectoryPath = moduleCacheURL.appendingPathComponent(subdirectoryName)
      for module in modules {
        result.insert(subdirectoryPath.appendingPathComponent(module.implicitFilename))
      }
    }
    return result
  }

  func testModuleCachePruning() {
    let fakes: (metadataFile: URL, moduleCache: URL)
    do {
      fakes = try createFakes(
        metadataFileWithExplicitModules: [
          modules.system.foundation, modules.system.coreFoundation, modules.user.buttonsLib,
          modules.user.buttonsIdentity,
        ],
        moduleCacheDirectoryWith: (
          swiftModules: [
            modules.system.foundation,
            modules.system.coreFoundation,
            modules.system.darwin,
          ],
          clangModules: [
            directoryHash1: [
              modules.user.buttonsLib, modules.user.buttonsIdentity,
              modules.user.buttonsModel,
            ],
            directoryHash2: [
              modules.system.foundation, modules.system.coreFoundation,
              modules.system.darwin,
            ],
          ]
        ))
    } catch TestSetupError.noModuleCache(let msg), TestSetupError.noMetadataFile(let msg) {
      XCTFail(msg)
      return
    } catch {
      XCTFail(error.localizedDescription)
      return
    }

    fakeMetadataFile = fakes.metadataFile
    fakeModuleCacheURL = fakes.moduleCache

    guard
      let actualModulesRemovedFromModuleCache = pruneModuleCache(
        moduleCachePath: fakes.moduleCache.path, explicitModuleMetadataFile: fakes.metadataFile.path
      )
    else {
      XCTFail("Module cache pruning returned nil but expected a list")
      return
    }

    let expectedModulesRemovedFromModuleCache = implicitModuleCacheURLs(
      fakes.moduleCache,
      forModulesInDirectories: [
        directoryHash1: [modules.user.buttonsLib, modules.user.buttonsIdentity],
        directoryHash2: [modules.system.foundation, modules.system.coreFoundation],
      ])

    assertSetsEqual(Set(actualModulesRemovedFromModuleCache), expectedModulesRemovedFromModuleCache)

    let actualFilenamesRemainingInModuleCache = getDirectoryContentsWithRelativePaths(
      directory: fakes.moduleCache)
    let expectedFilenamesRemainingInModuleCache = Set([
      modules.system.foundation.swiftName, modules.system.coreFoundation.swiftName,
      modules.system.darwin.swiftName,
      "\(directoryHash1)/\(modules.user.buttonsModel.implicitFilename)",
      "\(directoryHash2)/\(modules.system.darwin.implicitFilename)",
      directoryHash1, directoryHash2, prunedModulesTokenFilename,
    ])

    assertSetsEqual(actualFilenamesRemainingInModuleCache, expectedFilenamesRemainingInModuleCache)
  }

  func testModuleCachePruningNegativeCases() {
    let fakes: (metadataFile: URL, moduleCache: URL)

    do {
      
      
      fakes = try createFakes(
        metadataFileWithExplicitModules: [
          modules.system.foundation, modules.user.buttonsLib,
        ],
        moduleCacheDirectoryWith: (
          swiftModules: [],
          clangModules: [
            directoryHash1: [
              modules.user.buttonsIdentity, modules.user.buttonsModel,
            ],
            directoryHash2: [
              modules.system.coreFoundation, modules.system.darwin,
            ],
          ]
        ))
    } catch TestSetupError.noModuleCache(let msg), TestSetupError.noMetadataFile(let msg) {
      XCTFail(msg)
      return
    } catch {
      XCTFail(error.localizedDescription)
      return
    }

    fakeMetadataFile = fakes.metadataFile
    fakeModuleCacheURL = fakes.moduleCache

    guard
      let modulesRemovedFromModuleCache1 = pruneModuleCache(
        moduleCachePath: fakes.moduleCache.path, explicitModuleMetadataFile: fakes.metadataFile.path
      )
    else {
      XCTFail("Module cache pruning returned nil but expected an empty list")
      return
    }
    
    XCTAssertEqual(modulesRemovedFromModuleCache1.count, 0)

    let modulesRemovedFromModuleCache2 = pruneModuleCache(
      moduleCachePath: fakes.moduleCache.path, explicitModuleMetadataFile: fakes.metadataFile.path)
    
    XCTAssertNil(modulesRemovedFromModuleCache2)

    let metadataFileWithNoExplicitModules: URL
    do {
      metadataFileWithNoExplicitModules = try createFakeMetadataFile(withExplicitModules: [])
    } catch {
      XCTFail("Failed to create required fake metadata file: \(error)")
      return
    }
    let modulesRemovedFromModuleCache3 = pruneModuleCache(
      moduleCachePath: fakes.moduleCache.path,
      explicitModuleMetadataFile: metadataFileWithNoExplicitModules.path)
    
    
    XCTAssertNil(modulesRemovedFromModuleCache3)
  }
}
