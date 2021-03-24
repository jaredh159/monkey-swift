import XCTest
import monkey

final class MonkeyTests: XCTestCase {
  // these tests test the built binary, the real unit test suite
  // is in the monkey package, and can be run as described in the readme
  func testEval() throws {
    let cases = [
      ("1 + 2", "3"),
      ("{true: 5}[true]", "5"),
    ]
    cases.forEach { (input, expectedOutput) in
      try? runEvalTest(input: input, expectedOutput: expectedOutput)
    }
  }

  func runEvalTest(input: String, expectedOutput: String) throws {
    guard #available(macOS 10.13, *) else {
      return
    }

    let monkey = productsDirectory.appendingPathComponent("monkey")
    let process = Process()
    process.executableURL = monkey
    process.arguments = ["eval", input]

    let pipe = Pipe()
    process.standardOutput = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)

    XCTAssertEqual(output, "\(expectedOutput)\n")
  }

  /// Returns path to the built products directory.
  var productsDirectory: URL {
    #if os(macOS)
      for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
        return bundle.bundleURL.deletingLastPathComponent()
      }
      fatalError("couldn't find the products directory")
    #else
      return Bundle.main.bundleURL
    #endif
  }

  static var allTests = [
    ("testEval", testEval)
  ]
}
