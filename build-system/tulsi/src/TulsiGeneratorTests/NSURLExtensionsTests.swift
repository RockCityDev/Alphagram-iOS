

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class NSURLExtensionsTests: XCTestCase {
  func testRelativePathOfEqualPaths() {
    let rootURL = URL(fileURLWithPath: "/test")
    XCTAssertEqual(rootURL.relativePathTo(rootURL), "")
  }

  func testRelativePathOfSiblingsAtRoot() {
    let rootURL = URL(fileURLWithPath: "/root")
    let targetURL = URL(fileURLWithPath: "/target")
    XCTAssertEqual(rootURL.relativePathTo(targetURL), "../target")
  }

  func testRelativePathOfSiblingPaths() {
    let rootURL = URL(fileURLWithPath: "/test/root")
    let targetURL = URL(fileURLWithPath: "/test/target")
    XCTAssertEqual(rootURL.relativePathTo(targetURL), "../target")
  }

  func testRelativePathOfChildPath() {
    let rootURL = URL(fileURLWithPath: "/test/root")
    do {
      let targetURL = URL(fileURLWithPath: "/test/root/target")
      XCTAssertEqual(rootURL.relativePathTo(targetURL), "target")
    }
    do {
      let targetURL = URL(fileURLWithPath: "/test/root/deeply/nested/target")
      XCTAssertEqual(rootURL.relativePathTo(targetURL), "deeply/nested/target")
    }
  }

  func testRelativePathOfParentPath() {
    let rootURL = URL(fileURLWithPath: "/test/deep/path/to/root")
    do {
      let targetURL = URL(fileURLWithPath: "/test/deep/path/to")
      XCTAssertEqual(rootURL.relativePathTo(targetURL), "..")
    }
    do {
      let targetURL = URL(fileURLWithPath: "/test")
      XCTAssertEqual(rootURL.relativePathTo(targetURL), "../../../..")
    }
  }

  func testRelativePathOfNonFileURL() {
    let rootURL = URL(string: "http://this/is/not/a/path")!
    let targetURL = URL(fileURLWithPath: "/path")
    XCTAssertNil(rootURL.relativePathTo(targetURL))
  }
}
