

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import XCTest

@testable import ModuleCachePruner

class ExplicitModuleTests: XCTestCase {
  let modules = FakeModules()
  var fakeMetadataFile: URL?

  override func tearDown() {
    if let fakeMetadataFile = fakeMetadataFile {
      try? FileManager.default.removeItem(at: fakeMetadataFile)
    }
  }

  func testExtractingModuleNamesFromMetatdataFile() {
    do {
      fakeMetadataFile = try createFakeMetadataFile(
        withExplicitModules: [
          modules.system.foundation, modules.system.coreFoundation, modules.user.buttonsLib,
          modules.user.buttonsIdentity,
        ])
    } catch {
      XCTFail("Failed to create required fake metadata file: \(error)")
      return
    }

    let expectedExplicitModuleNames = [
      modules.system.foundation, modules.system.coreFoundation, modules.user.buttonsLib,
      modules.user.buttonsIdentity,
    ].map { $0.name }

    XCTAssertEqual(
      try? getExplicitModuleNames(fromMetadataFile: fakeMetadataFile!.path),
      expectedExplicitModuleNames
    )
  }
}
