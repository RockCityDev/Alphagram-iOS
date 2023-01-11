

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import BazelIntegrationTestCase
@testable import TulsiEndToEndTestBase
@testable import TulsiGenerator



class ButtonsNightlyEndToEndTest: TulsiEndToEndTest {
  fileprivate let buttonsProjectPath
    = "third_party/tulsi/src/TulsiEndToEndTests/Resources/Buttons.tulsiproj"

  override func setUp() {
    super.setUp()
    guard let nightlyBazelURL = fakeBazelWorkspace.nightlyBazelURL else {
      XCTFail("Expected Bazel nightly URL.")
      return
    }
    XCTAssert(
      fileManager.fileExists(atPath: nightlyBazelURL.path), "Bazel nightly binary is missing.")

    bazelURL = nightlyBazelURL
    let completionInfo = ProcessRunner.launchProcessSync(bazelURL.path, arguments: ["version"])
    if let versionOutput = String(data: completionInfo.stdout, encoding: .utf8) {
      print(versionOutput)
    }

    if !copyDataToFakeWorkspace("third_party/tulsi/src/TulsiEndToEndTests/Resources") {
      XCTFail("Failed to copy Buttons files to fake execroot.")
    }
  }

  func testButtonsWithNightlyBazel() throws {
    let xcodeProjectURL = generateXcodeProject(
      tulsiProject: buttonsProjectPath,
      config: "Buttons")
    XCTAssert(
      fileManager.fileExists(atPath: xcodeProjectURL.path), "Xcode project was not generated.")
    testXcodeProject(xcodeProjectURL, scheme: "ButtonsLogicTests")
  }
}
