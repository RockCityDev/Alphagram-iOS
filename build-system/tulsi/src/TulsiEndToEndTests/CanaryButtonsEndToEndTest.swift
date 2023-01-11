

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import BazelIntegrationTestCase
@testable import TulsiEndToEndTestBase
@testable import TulsiGenerator



class ButtonsEndToEndTest: TulsiEndToEndTest {
  fileprivate let buttonsProjectPath
    = "third_party/tulsi/src/TulsiEndToEndTests/Resources/Buttons.tulsiproj"

  override func setUp() {
    super.setUp()
    guard let canaryBazelURL = fakeBazelWorkspace.canaryBazelURL else {
      XCTFail("Expected Bazel canary URL.")
      return
    }
    XCTAssert(
      fileManager.fileExists(atPath: canaryBazelURL.path), "Bazel canary binary is missing.")

    bazelURL = canaryBazelURL
    let completionInfo = ProcessRunner.launchProcessSync(bazelURL.path, arguments: ["version"])
    if let versionOutput = String(data: completionInfo.stdout, encoding: .utf8) {
      print(versionOutput)
    }

    if !copyDataToFakeWorkspace("third_party/tulsi/src/TulsiEndToEndTests/Resources") {
      XCTFail("Failed to copy Buttons files to fake execroot.")
    }
  }

  func testButtonsWithCanaryBazel() throws {
    let xcodeProjectURL = generateXcodeProject(
      tulsiProject: buttonsProjectPath,
      config: "Buttons")
    XCTAssert(
      fileManager.fileExists(atPath: xcodeProjectURL.path), "Xcode project was not generated.")
    testXcodeProject(xcodeProjectURL, scheme: "ButtonsLogicTests")
  }
}
