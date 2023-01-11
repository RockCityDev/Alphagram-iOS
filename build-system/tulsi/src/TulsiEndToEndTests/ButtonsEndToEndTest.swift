

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import BazelIntegrationTestCase
@testable import TulsiEndToEndTestBase


class ButtonsEndToEndTest: TulsiEndToEndTest {
  fileprivate let buttonsProjectPath =
    "src/TulsiEndToEndTests/Resources/Buttons.tulsiproj"

  override func setUp() {
    super.setUp()

    if !copyDataToFakeWorkspace("src/TulsiEndToEndTests/Resources") {
      XCTFail("Failed to copy Buttons files to fake execroot.")
    }
  }

  func testButtons() throws {
    let xcodeProjectURL = generateXcodeProject(
      tulsiProject: buttonsProjectPath,
      config: "Buttons")
    XCTAssert(
      fileManager.fileExists(atPath: xcodeProjectURL.path), "Xcode project was not generated.")

    testXcodeProject(xcodeProjectURL, scheme: "ButtonsTests")

    let installingDsymBundlesOutput = "Installing dSYM bundles completed"

    let releaseBuildOutput = buildXcodeTarget(
      xcodeProjectURL, target: "Buttons", configuration: "Release")
    XCTAssert(releaseBuildOutput.contains(installingDsymBundlesOutput))

    let debugBuildOutput = buildXcodeTarget(
      xcodeProjectURL, target: "Buttons", configuration: "Debug")
    XCTAssertFalse(debugBuildOutput.contains(installingDsymBundlesOutput))
  }

  
  func testIndexingTargetsBuild() throws {
    let xcodeProjectURL = generateXcodeProject(
      tulsiProject: buttonsProjectPath,
      config: "Buttons")
    XCTAssert(
      fileManager.fileExists(atPath: xcodeProjectURL.path), "Xcode project was not generated.")
    let targets = targetsOfXcodeProject(xcodeProjectURL)
    let indexTargets = targets.filter { $0.hasPrefix("_idx_") }
    XCTAssertEqual(indexTargets.count, 6)
    for target in indexTargets {
      _ = buildXcodeTarget(xcodeProjectURL, target: target)
    }
  }

  func testInvalidConfig() throws {
    let xcodeProjectURL = generateXcodeProject(
      tulsiProject: buttonsProjectPath,
      config: "InvalidConfig")
    XCTAssertFalse(
      fileManager.fileExists(atPath: xcodeProjectURL.path),
      "Xcode project was generated despite invalid config.")
  }
}
