func testEval() {
  Test.reset(suiteName: "EvaluatorTest")

  test("eval integer expression") {
    let cases = [
      ("5", 5),
      ("10", 10),
      ("-5", -5),
      ("-10", -10),
      ("5 + 5 + 5 + 5 - 10", 10),
      ("2 * 2 * 2 * 2 * 2", 32),
      ("-50 + 100 + -50", 0),
      ("5 * 2 + 10", 20),
      ("5 + 2 * 10", 25),
      ("20 + 2 * -10", 0),
      ("50 / 2 * 2 + 10", 60),
      ("2 * (5 + 10)", 30),
      ("3 * 3 * 3 + 10", 37),
      ("3 * (3 * 3) + 10", 37),
      ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
    ]
    cases.forEach { (input, expected) in
      let evaluated = testEval(input)
      expect(evaluated).toBeObject(int: expected)
    }
  }

  test("eval boolean expression") {
    let cases = [
      ("true", true),
      ("false", false),
      ("1 < 2", true),
      ("1 > 2", false),
      ("1 < 1", false),
      ("1 > 1", false),
      ("1 == 1", true),
      ("1 != 1", false),
      ("1 == 2", false),
      ("1 != 2", true),
      ("true == true", true),
      ("false == false", true),
      ("true == false", false),
      ("true != false", true),
      ("false != true", true),
      ("(1 < 2) == true", true),
      ("(1 < 2) == false", false),
      ("(1 > 2) == true", false),
      ("(1 > 2) == false", true),
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(bool: expected)
    }
  }

  test("bang operator") {
    let cases = [
      ("!false", true),
      ("!5", false),
      ("!!true", true),
      ("!!false", false),
      ("!!5", true),
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(bool: expected)
    }
  }

  test("if else expressions") {
    let cases = [
      ("if (true) { 10 }", 10),
      ("if (false) { 10 }", nil),
      ("if (1) { 10 }", 10),
      ("if (1 < 2) { 10 }", 10),
      ("if (1 > 2) { 10 }", nil),
      ("if (1 > 2) { 10 } else { 20 }", 20),
      ("if (1 < 2) { 10 } else { 20 }", 10),
    ]
    cases.forEach { (input, expected) in
      let result = testEval(input)
      if let int = expected {
        expect(result).toBeObject(int: int)
      } else {
        expect(result).toBeNull()
      }
    }
  }

  test("return statements") {
    let cases = [
      ("return 10;", 10),
      ("return 10; 9;", 10),
      ("return 2 * 5; 9;", 10),
      ("9; return 2 * 5; 9;", 10),
      (
        """
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }
          return 1;
        }
        """,
        10
      ),
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(int: expected)
    }
  }

  test("error handling") {
    let cases = [
      (
        "5 + true;",
        "type mismatch: INTEGER + BOOLEAN"
      ),
      (
        "5 + true; 5;",
        "type mismatch: INTEGER + BOOLEAN"
      ),
      (
        "-true",
        "unknown operator: -BOOLEAN"
      ),
      (
        "true + false;",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "5; true + false; 5",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "if (10 > 1) { true + false; }",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "if (10 > 1) { if (10 > 1) { return true + false } return 1 }",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "foobar",
        "identifier not found: foobar"
      ),
    ]
    cases.forEach { (input, expectedError) in
      expect(testEval(input)).toBeObject(error: expectedError)

    }
  }

  test("let statements") {
    let cases = [
      ("let a = 5; a;", 5),
      ("let a = 5 * 5; a;", 25),
      ("let a = 5; let b = a; b;", 5),
      ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
    ]
    cases.forEach { (input, expectedInt) in
      expect(testEval(input)).toBeObject(int: expectedInt)
    }
  }

  Test.report()
}

func testEval(_ input: String) -> Object? {
  let parser = Parser(Lexer(input))
  let program = parser.parseProgram()
  return eval(program, Environment())
}
