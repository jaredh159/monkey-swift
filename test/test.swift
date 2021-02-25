struct Test {
  static var suite = "<suite:none>"
  static var current = "<test:none>"
  static var numFails = 0
  static var numPasses = 0
  static var failMessages: [String] = []
  static var passMessages: [String] = []

  static func reset(suiteName suite: String?) {
    Test.suite = suite ?? "<suite:none>"
    current = "<test:none>"
    numFails = 0
    numPasses = 0
    failMessages = []
    passMessages = []
  }

  static func pushFail(_ msg: String) {
    numFails += 1
    failMessages.append("X: (\(suite) -> \(current)) -- \(msg)")
  }

  static func pushPass() {
    numPasses += 1
    passMessages.append("√: (\(suite) -> \(current))")
  }

  static func report() {
    passMessages.forEach { _ in print("•".green, terminator: "") }
    if numFails > 0 {
      print("")
    }
    failMessages.forEach { print($0.red) }
    print("")
  }
}

struct Expectation {
  let actual: Any

  func toEqual(_ expected: String) {
    guard let actual = actual as? String else {
      Test.pushFail("`actual` val was not string, got type=\(type(of: self.actual))")
      return
    }
    if actual != expected {
      Test.pushFail("expected (String) \"\(expected)\", got \"\(actual)\"")
      return
    }
    Test.pushPass()
  }

  func toEqual(_ expected: TokenType) {
    guard let actual = actual as? TokenType else {
      Test.pushFail("`actual` val was not TokenType, got type=\(type(of: self.actual))")
      return
    }
    if actual.rawValue != expected.rawValue {
      Test.pushFail("expected (TokenType) \"\(expected.rawValue)\", got \"\(actual.rawValue)\"")
      return
    }
    Test.pushPass()
  }
}

func expect(_ actual: Any) -> Expectation {
  return Expectation(actual: actual)
}

func test(_ name: String, _ fn: () -> Void) {
  Test.current = name
  fn()
}
