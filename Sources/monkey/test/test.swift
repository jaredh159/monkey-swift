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
    print("\nTest suite:".grey, "\(suite)".magenta)
    passMessages.forEach { _ in print("•".green, terminator: "") }
    if numFails > 0 {
      print("")
      failMessages.forEach { print($0.red) }
    }
    print("")

    print("\(numPasses) passed ".green, terminator: "")
    if numFails > 0 {
      print("\(numFails) failed".red)
    } else {
      print("\n")
    }
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
  func toEqual(_ expected: Bool) -> Bool {
    guard let actual = actual as? Bool else {
      Test.pushFail("`actual` val was not Bool, got type=\(type(of: self.actual))")
      return false
    }
    if actual != expected {
      Test.pushFail("expected (Bool) \"\(expected)\", got \"\(actual)\"")
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
  func toBeBooleanLiteral(_ bool: Bool) -> Bool {
    guard let boolLit = expectType(actual, BooleanLiteral.self) else {
      return false
    }
    guard expect(boolLit.value).toEqual(bool) else {
      return false
    }
    return expect(boolLit.tokenLiteral).toEqual(bool ? "true" : "false")
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

  @discardableResult
  func toBeIdentifier(_ value: String) -> Bool {
    if actual == nil {
      Test.pushFail("expected type: Expression, got `nil`")
      return false
    }

    guard let ident = expectType(actual, Identifier.self) else {
      return false
    }

    return expect(ident.value).toEqual(value) && expect(ident.tokenLiteral).toEqual(value)
  }

  @discardableResult
  func toBeLiteralExpression(_ expected: Any) -> Bool {
    guard let expr = actual else {
      Test.pushFail("expected type: Expression, got `nil`")
      return false
    }

    switch expected {
      case let int as Int:
        return toBeIntegerLiteral(int)
      case let string as String:
        return toBeIdentifier(string)
      case let bool as Bool:
        return toBeBooleanLiteral(bool)
      default:
        Test.pushFail("type of expression not handled. got=\(type(of: expr))")
        return false
    }
  }

  @discardableResult
  func toBeInfixExpression(left: Any, op: String, right: Any) -> Bool {
    guard let infix = toBe(InfixExpression.self) else {
      return false
    }

    guard expect(infix.left).toBeLiteralExpression(left) else {
      return false
    }

    guard expect(infix.operator).toEqual(op) else {
      return false
    }

    return expect(infix.right).toBeLiteralExpression(right)
  }
}

func expect(_ actual: Any?) -> Expectation {
  return Expectation(actual: actual)
}

func xtest(_ name: String, _ fn: () -> Void) {
  print("skipping test \(name)".gray)
}

func test(_ name: String, _ fn: () -> Void) {
  Test.current = name
  fn()
}

func expectType<T>(_ actual: Any?, _ expectedType: T.Type) -> T? {
  return expect(actual).toBe(expectedType)
}
