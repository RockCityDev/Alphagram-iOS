

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class BuildLabelTests: XCTestCase {
  let a1 = BuildLabel("//test/place:a")
  let a2 = BuildLabel("//test/place:a")
  let b = BuildLabel("//test/place:b")
  let c = BuildLabel("//test/place:c")
  let noTargetName = BuildLabel("//test/place")
  let noLeadingSlash = BuildLabel("no/leading/slash")
  let emptyLabel = BuildLabel("")
  let justSlashLabel = BuildLabel("//")
  let invalidTrailingSlash = BuildLabel("invalid/trailing/slash/")

  func testEquality() {
    XCTAssertEqual(a1, a1)
    XCTAssertEqual(a1, a2)
    XCTAssertNotEqual(a1, b)
  }

  func testHash() {
    XCTAssertEqual(a1.hashValue, a2.hashValue)
  }

  func testComparison() {
    XCTAssertLessThan(a1, b)
    XCTAssertGreaterThan(c, b)
  }

  func testTargetName() {
    XCTAssertEqual(a1.targetName, "a")
    XCTAssertEqual(b.targetName, "b")
    XCTAssertEqual(c.targetName, "c")
    XCTAssertEqual(noTargetName.targetName, "place")
    XCTAssertNil(emptyLabel.targetName)
    XCTAssertNil(justSlashLabel.targetName)
    XCTAssertNil(invalidTrailingSlash.targetName)
  }

  func testPackageName() {
    XCTAssertEqual(a1.packageName, "test/place")
    XCTAssertEqual(a1.packageName, b.packageName)
    XCTAssertEqual(noLeadingSlash.packageName, "no/leading/slash")
    XCTAssertEqual(emptyLabel.packageName, "")
    XCTAssertEqual(justSlashLabel.packageName, "")
    XCTAssertEqual(invalidTrailingSlash.packageName, "")
  }

  func testAsFileName() {
    XCTAssertEqual(a1.asFileName, "test/place/a")
    XCTAssertEqual(a1.asFileName, a2.asFileName)
    XCTAssertEqual(noLeadingSlash.asFileName, "no/leading/slash/slash")
    XCTAssertNil(emptyLabel.asFileName)
    XCTAssertNil(justSlashLabel.asFileName)
    XCTAssertNil(invalidTrailingSlash.asFileName)
  }
}
