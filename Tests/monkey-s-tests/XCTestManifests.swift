import XCTest

#if !canImport(ObjectiveC)
  public func allTests() -> [XCTestCaseEntry] {
    return [
      testCase(monkey_sTests.allTests)
    ]
  }
#endif
