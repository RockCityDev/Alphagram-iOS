

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class TulsiOptionSetTests: XCTestCase {
  var optionKeys = [TulsiOptionKey]()

  override func setUp() {
    super.setUp()
    let optionSet = TulsiOptionSet()
    optionKeys = Array(optionSet.options.keys)
  }

  

  func testPersistenceIsReversible() {
    let target1 = "Target1"
    let target2 = "Target2"
    let optionSet = TulsiOptionSet()
    optionSet[.ALWAYS_SEARCH_USER_PATHS].projectValue = "YES"
    optionSet[.BazelBuildOptionsDebug].targetValues = [
      target1: "Target-Value1",
      target2: "Target-Value2",
    ]
    optionSet[.BazelBuildOptionsRelease].projectValue = "releaseProjectValue"
    optionSet[.BazelBuildOptionsRelease].targetValues = [
      target1: "Target-Release-Value1",
    ]
    var dict = [String: AnyObject]()
    optionSet.saveAllOptionsIntoDictionary(&dict)

    let optionsDict = TulsiOptionSet.getOptionsFromContainerDictionary(dict) ?? [:]
    let deserializedSet = TulsiOptionSet(fromDictionary: optionsDict)
    XCTAssertEqual(deserializedSet, optionSet)
  }

  func testPerUserOptionsAreOmitted() {
    let optionSet = TulsiOptionSet()
    for (_, option) in optionSet.options {
      option.projectValue = option.defaultValue
    }
    var dict = [String: Any]()
    optionSet.saveShareableOptionsIntoDictionary(&dict)

    let optionsDict = TulsiOptionSet.getOptionsFromContainerDictionary(dict) ?? [:]
    let deserializedSet = TulsiOptionSet(fromDictionary: optionsDict)
    for (key, option) in optionSet.options.filter({ !$1.optionType.contains(.PerUserOnly) }) {
      XCTAssertEqual(deserializedSet[key], option)
    }
  }

  func testValueSanitization() {
    let optionSet = TulsiOptionSet()
    let boolOptionKey = TulsiOptionKey.ALWAYS_SEARCH_USER_PATHS
    optionSet[boolOptionKey].projectValue = "invalid"
    let compilationModeKey = TulsiOptionKey.ProjectGenerationCompilationMode
    optionSet[compilationModeKey].projectValue = "also not valid."

    var dict = [String: AnyObject]()
    optionSet.saveAllOptionsIntoDictionary(&dict)

    let optionsDict = TulsiOptionSet.getOptionsFromContainerDictionary(dict) ?? [:]
    let deserializedSet = TulsiOptionSet(fromDictionary: optionsDict)

    for (key, option) in optionSet.options {
      if key == boolOptionKey {
        XCTAssertNotEqual(deserializedSet[key], option)
        XCTAssertEqual(deserializedSet[key].projectValue, "NO")
      } else if key == compilationModeKey {
        XCTAssertNotEqual(deserializedSet[key], option)
        XCTAssertEqual(deserializedSet[key].projectValue, "dbg")
      } else {
        XCTAssertEqual(deserializedSet[key], option)
      }
    }
  }

  func testOnlyPerUserOptionsArePersisted() {
    let optionSet = TulsiOptionSet()
    var i = 0
    for (_, option) in optionSet.options {
      option.projectValue = String(i)
      i += 10
    }
    var dict = [String: Any]()
    optionSet.savePerUserOptionsIntoDictionary(&dict)

    let perUserOptions = optionSet.options.filter({ $1.optionType.contains(.PerUserOnly) })
    let serializedValues = dict[TulsiOptionSet.PersistenceKey] as! [String: TulsiOption
      .PersistenceType]
    XCTAssertEqual(serializedValues.count, perUserOptions.count)

    let optionsDict = TulsiOptionSet.getOptionsFromContainerDictionary(dict) ?? [:]
    let deserializedSet = TulsiOptionSet(fromDictionary: optionsDict)
    for (key, option) in perUserOptions {
      XCTAssertEqual(deserializedSet[key], option)
    }
  }

  func testInheritance() {
    let parentValue = "ParentValue"
    let parent = TulsiOptionSet()
    parent[.BazelBuildOptionsDebug].projectValue = parentValue
    parent[.BazelBuildOptionsRelease].projectValue = parentValue
    parent[.BazelBuildStartupOptionsDebug].projectValue = parentValue
    parent[.BazelBuildStartupOptionsRelease].projectValue = parentValue
    parent[.ALWAYS_SEARCH_USER_PATHS].projectValue = "YES"
    parent[.SuppressSwiftUpdateCheck].projectValue = "NO"
    parent[.IncludeBuildSources].projectValue = "NO"

    let childValue = "ChildValue"
    let child = TulsiOptionSet(withInheritanceEnabled: true)
    child[.BazelBuildOptionsDebug].projectValue = childValue
    child[.BazelBuildOptionsRelease].projectValue = "\(childValue) $(inherited)"
    child[.BazelBuildStartupOptionsDebug].targetValues?["test"] = childValue
    child[.SuppressSwiftUpdateCheck].projectValue = "YES"

    let merged = child.optionSetByInheritingFrom(parent)
    XCTAssertEqual(merged[.BazelBuildOptionsDebug].commonValue, childValue)
    XCTAssertEqual(merged[.BazelBuildOptionsRelease].commonValue, "\(childValue) \(parentValue)")
    XCTAssertEqual(merged[.BazelBuildStartupOptionsDebug].targetValues?["test"], childValue)
    XCTAssertEqual(merged[.ALWAYS_SEARCH_USER_PATHS].commonValueAsBool, true)
    XCTAssertEqual(merged[.SuppressSwiftUpdateCheck].commonValueAsBool, true)
  }
}
