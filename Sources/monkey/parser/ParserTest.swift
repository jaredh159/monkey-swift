func testParser() {
  Test.reset(suiteName: "ParserTest")

  test("let statements") {
    let input = """
      let x = 5;
      let y = 10;
      let foobar = 838383;
      """

    guard let statements = expectStatements(input, 3) else {
      return
    }

    for (idx, expectedIdentifier) in ["x", "y", "foobar"].enumerated() {
      testLetStatement(statements[idx], expectedIdentifier)
    }
  }

  test("return statements") {
    let input = """
      return 5;
      return 10;
      return 993322;
      """

    guard let statements = expectStatements(input, 3) else {
      return
    }

    for statement in statements {
      guard let returnStmt = expectType(statement, ReturnStatement.self) else {
        return
      }
      expect(returnStmt.tokenLiteral).toEqual("return")
    }
  }

  test("identifier expression") {
    guard let exprStmt = expectFirstExpr("foobar;", 1) else {
      return
    }
    expect(exprStmt.expression).toBeIdentifier("foobar")
  }

  test("boolean expression") {
    guard let exprStmt = expectFirstExpr("true;", 1) else {
      return
    }
    expect(exprStmt.expression).toBeBooleanLiteral(true)
  }

  test("integer expression") {
    guard let exprStmt = expectFirstExpr("5;", 1) else {
      return
    }
    expect(exprStmt.expression).toBeIntegerLiteral(5)
  }

  test("prefix expressions") {
    let cases: [(String, String, Any)] = [
      ("!5", "!", 5),
      ("-15", "-", 15),
      ("!true", "!", true),
      ("!false", "!", false),
    ]

    cases.forEach { (input, op, expectedLiteral) in
      guard let exprStmt = expectFirstExpr(input, 1) else {
        return
      }
      guard let exp = expectType(exprStmt.expression!, PrefixExpression.self) else {
        return
      }
      expect(exp.operator).toEqual(op)
      expect(exp.right).toBeLiteralExpression(expectedLiteral)
    }
  }

  test("infix expressions") {
    let cases: [(String, Any, String, Any)] = [
      ("5 + 5;", 5, "+", 5),
      ("5 - 5;", 5, "-", 5),
      ("5 * 5;", 5, "*", 5),
      ("5 / 5;", 5, "/", 5),
      ("5 > 5;", 5, ">", 5),
      ("5 < 5;", 5, "<", 5),
      ("5 == 5;", 5, "==", 5),
      ("5 != 5;", 5, "!=", 5),
      ("true == true", true, "==", true),
      ("true != false", true, "!=", false),
      ("false == false", false, "==", false),
    ]

    cases.forEach { (input, left, op, right) in
      guard let expr = expectFirstExpr(input, 1) else {
        return
      }
      expect(expr.expression).toBeInfixExpression(left: left, op: op, right: right)
    }
  }

  test("operator precedence parsing") {
    let cases = [
      (
        "-a * b",
        "((-a) * b)"
      ),
      (
        "!-a",
        "(!(-a))"
      ),
      (
        "a + b + c",
        "((a + b) + c)"
      ),
      (
        "a + b - c",
        "((a + b) - c)"
      ),
      (
        "a * b * c",
        "((a * b) * c)"
      ),
      (
        "a * b / c",
        "((a * b) / c)"
      ),
      (
        "a + b / c",
        "(a + (b / c))"
      ),
      (
        "a + b * c + d / e - f",
        "(((a + (b * c)) + (d / e)) - f)"
      ),
      (
        "3 + 4; -5 * 5",
        "(3 + 4)((-5) * 5)"
      ),
      (
        "5 > 4 == 3 < 4",
        "((5 > 4) == (3 < 4))"
      ),
      (
        "5 < 4 != 3 > 4",
        "((5 < 4) != (3 > 4))"
      ),
      (
        "3 + 4 * 5 == 3 * 1 + 4 * 5",
        "((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))"
      ),
      (
        "true",
        "true"
      ),
      (
        "false",
        "false"
      ),
      (
        "3 > 5 == false",
        "((3 > 5) == false)"
      ),
      (
        "3 < 5 == true",
        "((3 < 5) == true)"
      ),
      (
        "1 + (2 + 3) + 4",
        "((1 + (2 + 3)) + 4)"
      ),
      (
        "(5 + 5) * 2",
        "((5 + 5) * 2)"
      ),
      (
        "2 / (5 + 5)",
        "(2 / (5 + 5))"
      ),
      (
        "-(5 + 5)",
        "(-(5 + 5))"
      ),
      (
        "!(true == true)",
        "(!(true == true))"
      ),
      (
        "a + add(b * c) + d",
        "((a + add((b * c))) + d)"
      ),
      (
        "add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))",
        "add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))"
      ),
      (
        "add(a + b + c * d / f + g)",
        "add((((a + b) + ((c * d) / f)) + g))"
      ),
    ]

    cases.forEach { (input, expectedString) in
      let parser = Parser(Lexer(input))
      let program = parser.parseProgram()
      guard noParserErrors(parser) else {
        return
      }
      expect(program.string).toEqual(expectedString)
    }
  }

  test("if expression") {
    let cases = [
      ("if (x < y) { x }", ""),
      ("if (x < y) { x } else { y }", "y"),
    ]

    cases.forEach { (input, expectedAlt) in
      guard let stmt = expectFirstExpr(input, 1) else {
        return
      }
      guard let ifExp = expect(stmt.expression).toBe(IfExpression.self) else {
        return
      }
      guard expect(ifExp.condition).toBeInfixExpression(left: "x", op: "<", right: "y") else {
        return
      }
      guard let cons = expect(ifExp.consequence).toBe(BlockStatement.self) else {
        return
      }
      guard expect(cons.statements.count).toEqual(1) else {
        return
      }
      guard let firstCons = cons.statements.first else {
        return
      }
      guard let consExprStmt = expect(firstCons).toBe(ExpressionStatement.self) else {
        return
      }
      guard expect(consExprStmt.expression).toBeIdentifier("x") else {
        return
      }
      if expectedAlt == "" {
        expect(ifExp.alternative).toBeNil()
        return
      }
      guard let alt = expect(ifExp.alternative).toBe(BlockStatement.self) else {
        return
      }
      guard expect(alt.statements.count).toEqual(1) else {
        return
      }
      guard let firstAlt = alt.statements.first else {
        return
      }
      guard let altExprStmt = expect(firstAlt).toBe(ExpressionStatement.self) else {
        return
      }
      guard expect(altExprStmt.expression).toBeIdentifier(expectedAlt) else {
        return
      }
    }
  }

  test("function literals") {
    let input = "fn(x, y) { x + y; }"
    guard let exprStmt = expectFirstExpr(input, 1) else {
      return
    }
    guard let fnLit = expect(exprStmt.expression).toBe(FunctionLiteral.self) else {
      return
    }
    guard expect(fnLit.parameters.count).toEqual(2) else {
      return
    }
    expect(fnLit.parameters[0]).toBeLiteralExpression("x")
    expect(fnLit.parameters[1]).toBeLiteralExpression("y")
    guard let body = fnLit.body else {
      Test.pushFail("unexpected nil for function literal body")
      return
    }
    guard expect(body.statements.count).toEqual(1) else {
      return
    }
    guard let bodyStmt = expect(body.statements[0]).toBe(ExpressionStatement.self) else {
      return
    }
    expect(bodyStmt.expression).toBeInfixExpression(left: "x", op: "+", right: "y")
  }

  test("function parameter parsing") {
    let cases = [
      ("fn() {}", []),
      ("fn(x) {}", ["x"]),
      ("fn(x, y, z) {}", ["x", "y", "z"]),
    ]
    cases.forEach { (input, expectedParams) in
      guard let exprStmt = expectFirstExpr(input, 1) else {
        return
      }
      guard let fnLit = expect(exprStmt.expression).toBe(FunctionLiteral.self) else {
        return
      }
      guard expect(fnLit.parameters.count).toEqual(expectedParams.count) else {
        return
      }
      for (param, expected) in zip(fnLit.parameters, expectedParams) {
        expect(param).toBeLiteralExpression(expected)
      }
    }
  }

  test("call expression parsing") {
    let input = "add(1, 2 * 3, 4 + 5);"
    guard let exprStmt = expectFirstExpr(input, 1) else {
      return
    }
    guard let callExp = expect(exprStmt.expression).toBe(CallExpression.self) else {
      return
    }
    guard expect(callExp.function).toBeIdentifier("add") else {
      return
    }
    guard expect(callExp.arguments.count).toEqual(3) else {
      return
    }
    expect(callExp.arguments[0]).toBeLiteralExpression(1)
    expect(callExp.arguments[1]).toBeInfixExpression(left: 2, op: "*", right: 3)
    expect(callExp.arguments[2]).toBeInfixExpression(left: 4, op: "+", right: 5)
  }

  Test.report()
}

func expectFirstExpr(_ input: String, _ numStatements: Int) -> ExpressionStatement? {
  guard let statements = expectStatements(input, numStatements) else {
    return nil
  }
  guard let exprStmt = expectType(statements[0], ExpressionStatement.self) else {
    return nil
  }
  return exprStmt
}

func expectStatements(_ input: String, _ expectedNumStatements: Int) -> [Statement]? {
  let parser = Parser(Lexer(input))
  let program = parser.parseProgram()
  guard noParserErrors(parser) else { return nil }
  let statements = program.statements
  guard expect(statements.count).toEqual(expectedNumStatements) else { return nil }
  return statements
}

func testLetStatement(_ statement: Statement?, _ name: String) {
  guard let statement = expectType(statement, Statement.self) else {
    return
  }
  guard let letStatement = expectType(statement, LetStatement.self) else {
    return
  }
  if expect(letStatement.name?.value).toEqual(name) {
    return
  }
  expect(letStatement.name?.tokenLiteral).toEqual(name)
}

func noParserErrors(_ parser: Parser) -> Bool {
  if parser.errors.isEmpty {
    Test.pushPass()
    return true
  }

  Test.pushFail("parser had \(parser.errors.count) errors")
  for err in parser.errors {
    Test.pushFail("parser error: \(err)")
  }
  return false
}
