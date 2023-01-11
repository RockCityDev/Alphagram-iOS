

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class TulsiProjectTests: XCTestCase {
  let projectName = "TestProject"
  let projectBundleURL = URL(fileURLWithPath: "/test/project/tulsiproject/")
  let workspaceRootURL = URL(fileURLWithPath: "/test/project/root/")

  
  let relativeRootPath = "../root"

  let bazelPackages = [
    "some/package",
    "another/package",
    "package",
  ]

  var project: TulsiProject! = nil

  override func setUp() {
    super.setUp()
    project = TulsiProject(
      projectName: projectName,
      projectBundleURL: projectBundleURL,
      workspaceRootURL: workspaceRootURL,
      bazelPackages: bazelPackages)
  }

  func testSave() {
    do {
      let data = try project.save()
      let dict = try JSONSerialization.jsonObject(
        with: data as Data, options: JSONSerialization.ReadingOptions()) as! [String: Any]
      XCTAssertEqual(dict["packages"] as! [String], bazelPackages.sorted())
      XCTAssertEqual(dict["projectName"] as! String, projectName)
      XCTAssertEqual(dict["workspaceRoot"] as! String, relativeRootPath)
    } catch {
      XCTFail("Unexpected assertion")
    }
  }

  func testLoad() {
    do {
      let dict = [
        "packages": bazelPackages,
        "projectName": projectName,
        "workspaceRoot": relativeRootPath,
      ] as [String: Any]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: JSONSerialization.WritingOptions())
      project = try TulsiProject(data: data, projectBundleURL: projectBundleURL)

      XCTAssertEqual(project.bazelPackages, bazelPackages)
      XCTAssertEqual(project.projectName, projectName)
      XCTAssertEqual(project.workspaceRootURL, workspaceRootURL)
    } catch {
      XCTFail("Unexpected assertion")
    }
  }

  func testLoadWithTrailingSlash() {
    do {
      let dict = [
        "packages": bazelPackages,
        "projectName": projectName,
        "workspaceRoot": relativeRootPath + "/",
      ] as [String: Any]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: JSONSerialization.WritingOptions())
      project = try TulsiProject(data: data, projectBundleURL: projectBundleURL)

      XCTAssertEqual(project.bazelPackages, bazelPackages)
      XCTAssertEqual(project.projectName, projectName)
      XCTAssertEqual(project.workspaceRootURL, workspaceRootURL)
    } catch {
      XCTFail("Unexpected assertion")
    }
  }

  func testLoadWithNoWorkspaceRoot() {
    do {
      let dict = [
        "packages": bazelPackages,
        "projectName": projectName,
      ] as [String: Any]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: JSONSerialization.WritingOptions())
      let _ = try TulsiProject(data: data, projectBundleURL: projectBundleURL)
      XCTFail("Unexpectedly succeeded without a workspace root")
    } catch TulsiProject.ProjectError.deserializationFailed {
      
    } catch {
      XCTFail("Unexpected assertion type")
    }
  }

  func testLoadWithAbsoluteWorkspaceRoot() {
    do {
      let dict = [
        "packages": bazelPackages,
        "projectName": projectName,
        "workspaceRoot": "/invalid/absolute/path",
      ] as [String: Any]
      let data = try JSONSerialization.data(
        withJSONObject: dict, options: JSONSerialization.WritingOptions())
      let _ = try TulsiProject(data: data, projectBundleURL: projectBundleURL)
      XCTFail("Unexpectedly succeeded with an invalid workspace root")
    } catch TulsiProject.ProjectError.deserializationFailed {
      
    } catch {
      XCTFail("Unexpected assertion type")
    }
  }
}
