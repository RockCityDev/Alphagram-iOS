

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest
@testable import BazelIntegrationTestCase
@testable import TulsiGenerator



class QueryTests_PackageRuleExtraction: BazelIntegrationTestCase {
  var infoExtractor: BazelQueryInfoExtractor! = nil

  override func setUp() {
    super.setUp()
    infoExtractor = BazelQueryInfoExtractor(bazelURL: bazelURL,
                                            workspaceRootURL: workspaceRootURL!,
                                            bazelUniversalFlags: bazelUniversalFlags,
                                            localizedMessageLogger: localizedMessageLogger)
  }

  func testSimple() {
    installBUILDFile("Simple", intoSubdirectory: "tulsi_test")
    let infos = infoExtractor.extractTargetRulesFromPackages(["tulsi_test"])

    let checker = InfoChecker(ruleInfos: infos)

    checker.assertThat("//tulsi_test:Application")
        .hasType("ios_application")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:TargetApplication")
      .hasType("ios_application")
      .hasNoLinkedTargetLabels()
      .hasNoDependencies()

    checker.assertThat("//tulsi_test:ApplicationLibrary")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:Library")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:TestLibrary")
      .hasType("objc_library")
      .hasNoLinkedTargetLabels()
      .hasNoDependencies()

    checker.assertThat("//tulsi_test:XCTest")
        .hasType("ios_unit_test")
        .hasExactlyOneLinkedTargetLabel(BuildLabel("//tulsi_test:Application"))
        .hasNoDependencies()

    checker.assertThat("//tulsi_test:ccLibrary")
      .hasType("cc_library")
      .hasNoLinkedTargetLabels()
      .hasNoDependencies()

    checker.assertThat("//tulsi_test:ccBinary")
      .hasType("cc_binary")
      .hasNoLinkedTargetLabels()
      .hasNoDependencies()

    checker.assertThat("//tulsi_test:ccTest")
      .hasType("cc_test")
      .hasNoLinkedTargetLabels()
      .hasNoDependencies()
  }


  func testComplexSingle() {
    installBUILDFile("ComplexSingle", intoSubdirectory: "tulsi_complex_test")
    let infos = infoExtractor.extractTargetRulesFromPackages(["tulsi_complex_test"])

    let checker = InfoChecker(ruleInfos: infos)

    checker.assertThat("//tulsi_complex_test:Application")
        .hasType("ios_application")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:ApplicationResources")
        .hasType("apple_resource_group")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:ApplicationLibrary")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:ObjCBundle")
        .hasType("apple_bundle_import")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:CoreDataResources")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:Library")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:SubLibrary")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:SubLibraryWithDefines")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:SubLibraryWithIdenticalDefines")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:SubLibraryWithDifferentDefines")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:ObjCFramework")
        .hasType("apple_static_framework_import")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:TodayExtensionLibrary")
        .hasType("objc_library")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:TodayExtension")
        .hasType("ios_extension")
        .hasNoLinkedTargetLabels()
        .hasNoDependencies()

    checker.assertThat("//tulsi_complex_test:XCTest")
        .hasType("ios_unit_test")
        .hasExactlyOneLinkedTargetLabel(BuildLabel("//tulsi_complex_test:Application"))
        .hasNoDependencies()
  }
}



class QueryTests_BuildFilesExtraction: BazelIntegrationTestCase {
  var infoExtractor: BazelQueryInfoExtractor! = nil
  let testDir = "Buildfiles"

  override func setUp() {
    super.setUp()
    infoExtractor = BazelQueryInfoExtractor(bazelURL: bazelURL,
                                            workspaceRootURL: workspaceRootURL!,
                                            bazelUniversalFlags: bazelUniversalFlags,
                                            localizedMessageLogger: localizedMessageLogger)
    installBUILDFile("ComplexSingle", intoSubdirectory: testDir)
  }

  func testExtractBuildfiles() {
    let targets = [
      BuildLabel("//\(testDir):Application"),
      BuildLabel("//\(testDir):TodayExtension"),
    ]

    let fileLabels = infoExtractor.extractBuildfiles(targets)
    XCTAssert(infoExtractor.hasQueuedInfoMessages)

    
    
    
    XCTAssert(fileLabels.contains(BuildLabel("//\(testDir):BUILD")))
    XCTAssert(fileLabels.contains(BuildLabel("//\(testDir):ComplexSingle.bzl")))
  }
}


private class InfoChecker {
  let infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]

  init(infos: [RuleInfo: Set<BuildLabel>]) {
    var infoMap = [BuildLabel: (RuleInfo, Set<BuildLabel>)]()
    for (info, dependencies) in infos {
      infoMap[info.label] = (info, dependencies)
    }
    self.infoMap = infoMap
  }

  convenience init(ruleInfos: [RuleInfo]) {
    var infoDict = [RuleInfo: Set<BuildLabel>]()
    for info in ruleInfos {
      infoDict[info] = Set<BuildLabel>()
    }
    self.init(infos: infoDict)
  }

  func assertThat(_ targetLabel: String, line: UInt = #line) -> Context {
    guard let (ruleInfo, dependencies) = infoMap[BuildLabel(targetLabel)] else {
      XCTFail("No rule with the label \(targetLabel) was found", line: line)
      return Context(ruleInfo: nil, dependencies: nil, infoMap: infoMap)
    }

    return Context(ruleInfo: ruleInfo, dependencies: dependencies, infoMap: infoMap)
  }

  
  class Context {
    let ruleInfo: RuleInfo?
    let dependencies: Set<BuildLabel>?
    let infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]

    init(ruleInfo: RuleInfo?,
         dependencies: Set<BuildLabel>?,
         infoMap: [BuildLabel: (RuleInfo, Set<BuildLabel>)]) {
      self.ruleInfo = ruleInfo
      self.dependencies = dependencies
      self.infoMap = infoMap
    }

    // Does nothing as "assertThat" already asserted the existence of the associated ruleInfo.
    func exists() -> Context {
      return self
    }

    
    func hasType(_ type: String, line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      XCTAssertEqual(ruleInfo.type, type, line: line)
      return self
    }

    
    func hasLinkedTargetLabels(_ labels: Set<BuildLabel>, line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      XCTAssertEqual(ruleInfo.linkedTargetLabels, labels, line: line)
      return self
    }

    
    func hasExactlyOneLinkedTargetLabel(_ label: BuildLabel, line: UInt = #line) -> Context {
      return hasLinkedTargetLabels(Set<BuildLabel>([label]), line: line)
    }

    
    func hasNoLinkedTargetLabels(_ line: UInt = #line) -> Context {
      guard let ruleInfo = ruleInfo else { return self }
      if !ruleInfo.linkedTargetLabels.isEmpty {
        XCTFail("Expected no linked targets but found \(ruleInfo.linkedTargetLabels)", line: line)
      }
      return self
    }

    
    func hasDependencies(_ dependencies: Set<BuildLabel>, line: UInt = #line) -> Context {
      guard let ruleDeps = self.dependencies else { return self }
      XCTAssertEqual(ruleDeps, dependencies, line: line)
      return self
    }

    
    @discardableResult
    func hasDependencies(_ dependencies: [String], line: UInt = #line) -> Context {
      let labels = dependencies.map() { BuildLabel($0) }
      return hasDependencies(Set<BuildLabel>(labels), line: line)
    }

    
    @discardableResult
    func hasNoDependencies(_ line: UInt = #line) -> Context {
      if let ruleDeps = self.dependencies, !ruleDeps.isEmpty {
        XCTFail("Expected no dependencies but found \(ruleDeps)", line: line)
      }
      return self
    }
  }
}
