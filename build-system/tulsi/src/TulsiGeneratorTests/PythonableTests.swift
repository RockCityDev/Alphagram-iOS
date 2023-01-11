

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import XCTest

@testable import TulsiGenerator

class PythonableTests: XCTestCase {

  func testStringSimple() {
    XCTAssertEqual("foobar".toPython(""), "'foobar'")
    XCTAssertEqual("foobar".toPython("  "), "'foobar'")
    XCTAssertEqual("this is a string".toPython(""), "'this is a string'")
  }

  func testStringEscapesSingleQuotes() {
    XCTAssertEqual("foo'bar".toPython(""), "'foo\\'bar'")
    XCTAssertEqual("foo'bar".toPython("  "), "'foo\\'bar'")
    XCTAssertEqual("this''string".toPython(""), "'this\\'\\'string'")
  }

  func testArrayEmpty() {
    XCTAssertEqual([String]().toPython(""), "[]")
  }

  func testArrayOfStrings() {
    let arr = [
      "Hello",
      "Goodbye",
      "'Escape'",
    ]
    XCTAssertEqual(arr.toPython(""), """
[
    'Hello',
    'Goodbye',
    '\\'Escape\\'',
]
""")
    XCTAssertEqual(
      arr.toPython("  "), """
[
      'Hello',
      'Goodbye',
      '\\'Escape\\'',
  ]
""")
  }

  func testSetEmpty() {
    XCTAssertEqual(Set<String>().toPython(""), "set()")
  }

  func testStringSet() {
    let set: Set<String> = ["Hello"]
    XCTAssertEqual(set.toPython(""), """
set([
    'Hello',
])
""")
    XCTAssertEqual(set.toPython("  "), """
set([
      'Hello',
  ])
""")
  }

  func testDictionaryEmpty() {
    XCTAssertEqual([String: String]().toPython(""), "{}")
  }

  func testStringDictionary() {
    let dict = ["Type": "A"]
    XCTAssertEqual(dict.toPython(""), """
{
    'Type': 'A',
}
""")
    XCTAssertEqual(dict.toPython(" "), """
{
     'Type': 'A',
 }
""")
  }
}
