

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import XCTest

@testable import ModuleCachePruner




func convertArrayValuesToSetValues(_ input: [String: [URL]]) -> [String: Set<URL>] {
  return Dictionary(uniqueKeysWithValues: input.map { ($0, Set($1)) })
}

class ImplicitModuleTests: XCTestCase {
  let modules = FakeModules()
  var fakeModuleCacheURL: URL?

  override func tearDown() {
    if let moduleCacheURL = fakeModuleCacheURL {
      try? FileManager.default.removeItem(at: moduleCacheURL)
    }
  }

  func testMappingModulesInModuleCache() {
    guard
      let moduleCacheURL = createFakeModuleCache(
        withSwiftModules: [
          modules.system.foundation, modules.system.coreFoundation, modules.system.darwin,
        ],
        andClangModules: [
          "DirectoryHash1": [
            modules.user.buttonsLib, modules.user.buttonsIdentity, modules.user.buttonsModel,
          ],
          "DirectoryHash2": [
            modules.user.buttonsLib, modules.user.buttonsIdentity, modules.user.buttonsModel,
          ],
        ])
    else {
      XCTFail("Failed to create fake module cache required for test.")
      return
    }

    fakeModuleCacheURL = moduleCacheURL

    let subdirectory1 = moduleCacheURL.appendingPathComponent("DirectoryHash1")
    let subdirectory2 = moduleCacheURL.appendingPathComponent("DirectoryHash2")
    let expectedImplicitModuleMapping = [
      modules.user.buttonsLib.name: [
        subdirectory1.appendingPathComponent(modules.user.buttonsLib.implicitFilename),
        subdirectory2.appendingPathComponent(modules.user.buttonsLib.implicitFilename),
      ],
      modules.user.buttonsIdentity.name: [
        subdirectory1.appendingPathComponent(modules.user.buttonsIdentity.implicitFilename),
        subdirectory2.appendingPathComponent(modules.user.buttonsIdentity.implicitFilename),
      ],
      modules.user.buttonsModel.name: [
        subdirectory1.appendingPathComponent(modules.user.buttonsModel.implicitFilename),
        subdirectory2.appendingPathComponent(modules.user.buttonsModel.implicitFilename),
      ],
    ]

    let actualImplicitModuleMapping = getImplicitModules(moduleCacheURL: moduleCacheURL)
    XCTAssertEqual(
      convertArrayValuesToSetValues(actualImplicitModuleMapping),
      convertArrayValuesToSetValues(expectedImplicitModuleMapping))
  }
}
