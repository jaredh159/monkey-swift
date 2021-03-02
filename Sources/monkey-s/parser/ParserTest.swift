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
    guard let expr = expectType(exprStmt.expression!, Expression.self) else {
      return
    }
    guard let ident = expectType(expr, Identifier.self) else {
      return
    }

    expect(ident.value).toEqual("foobar")
    expect(ident.tokenLiteral).toEqual("foobar")
  }

  test("integer expression") {
    guard let exprStmt = expectFirstExpr("5;", 1) else {
      return
    }
    guard let expr = expectType(exprStmt.expression!, Expression.self) else {
      return
    }
    expect(expr).toBeIntegerLiteral(5)
  }

  test("prefix expressions") {
    let cases = [
      ("!5", "!", 5),
      ("-15", "-", 15),
    ]

    cases.forEach { (input, op, int) in
      guard let exprStmt = expectFirstExpr(input, 1) else {
        return
      }
      guard let exp = expectType(exprStmt.expression!, PrefixExpression.self) else {
        return
      }
      expect(exp.operator).toEqual(op)
      expect(exp.right).toBeIntegerLiteral(int)
    }
  }

  test("infix expressions") {
    let cases = [
      ("5 + 5;", 5, "+", 5),
      ("5 - 5;", 5, "-", 5),
      ("5 * 5;", 5, "*", 5),
      ("5 / 5;", 5, "/", 5),
      ("5 > 5;", 5, ">", 5),
      ("5 < 5;", 5, "<", 5),
      ("5 == 5;", 5, "==", 5),
      ("5 != 5;", 5, "!=", 5),
    ]

    cases.forEach { (input, left, op, right) in
      guard let expr = expectFirstExpr(input, 1) else {
        return
      }
      guard let infix = expectType(expr.expression!, InfixExpression.self) else {
        return
      }
      expect(infix.left).toBeIntegerLiteral(left)
      expect(infix.operator).toEqual(op)
      expect(infix.right).toBeIntegerLiteral(left)
    }
  }

  // @TODO make "precedence parsing" test from btm of p. 67 next
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
