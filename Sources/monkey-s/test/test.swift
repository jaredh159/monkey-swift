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

    print("\(numPasses) passed ".green, "\(numFails) failed\n".red)
  }
}

struct Expectation {
  let actual: Any?

  @discardableResult
  func toEqual(_ expected: Int) -> Bool {
    guard let actual = actual as? Int else {
      Test.pushFail("`actual` val was not Int, got type=\(type(of: self.actual))")
      return false
    }
    if actual != expected {
      Test.pushFail("expected (Int) \"\(expected)\", got \"\(actual)\"")
      return false
    }
    Test.pushPass()
    return true
  }

  @discardableResult
  func toEqual(_ expected: String) -> Bool {
    guard let actual = actual as? String else {
      Test.pushFail("`actual` val was not String, got type=\(type(of: self.actual))")
      return false
    }
    if actual != expected {
      Test.pushFail("expected (String) \"\(expected)\", got \"\(actual)\"")
      return false
    }
    Test.pushPass()
    return true
  }

  @discardableResult
  func toEqual(_ expected: TokenType) -> Bool {
    guard let actual = actual as? TokenType else {
      Test.pushFail("`actual` val was not TokenType, got type=\(type(of: self.actual))")
      return false
    }
    if actual.rawValue != expected.rawValue {
      Test.pushFail("expected (TokenType) \"\(expected.rawValue)\", got \"\(actual.rawValue)\"")
      return false
    }
    Test.pushPass()
    return true
  }

  @discardableResult
  func toBe<T>(_ expectedType: T.Type) -> T? {
    guard let knownType = actual as? T else {
      Test.pushFail(
        "expected `actual` to be type=\(expectedType.self), got=\(type(of: self.actual))")
      return nil
    }
    Test.pushPass()
    return knownType
  }

  @discardableResult
  func toBeNil() -> Any? {
    if actual != nil {
      Test.pushFail("expected `actual` to be `nil`, got type=\(type(of: self.actual))")
      return Optional.some(actual!)
    }
    Test.pushPass()
    return Optional.none
  }

  @discardableResult
  func notToBeNil() -> Any? {
    if actual == nil {
      Test.pushFail("expected `actual` to not be `nil`, but it was `nil`")
      return Optional.none
    }
    Test.pushPass()
    return Optional.some(actual!)
  }

  @discardableResult
  func toBeIntegerLiteral(_ int: Int) -> Bool {
    guard let intLit = expectType(actual, IntegerLiteral.self) else {
      return false
    }
    guard expect(intLit.value).toEqual(int) else {
      return false
    }
    return expect(intLit.tokenLiteral).toEqual(String(int))
  }
}

func expect(_ actual: Any?) -> Expectation {
  return Expectation(actual: actual)
}

func test(_ name: String, _ fn: () -> Void) {
  Test.current = name
  fn()
}

func expectType<T>(_ actual: Any?, _ expectedType: T.Type) -> T? {
  return expect(actual).toBe(expectedType)
}
