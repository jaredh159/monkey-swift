func main() {
  Test.reset(suiteName: "ParserTest")

  test("let statements") {
    let input = """
      let x = 5;
      let y = 10;
      let foobar = 838383;
      """

    guard let statements = expectParsed(input, 3) else {
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

    guard let statements = expectParsed(input, 3) else {
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
    guard let statements = expectParsed("foobar;", 1) else {
      return
    }
    guard let exprStmt = expectType(statements[0], ExpressionStatement.self) else {
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
    guard let statements = expectParsed("5;", 1) else {
      return
    }

    guard let exprStmt = expectType(statements[0], ExpressionStatement.self) else {
      return
    }
    guard let expr = expectType(exprStmt.expression!, Expression.self) else {
      return
    }
    guard let int = expectType(expr, IntegerLiteral.self) else {
      return
    }

    expect(int.value).toEqual(5)
    expect(int.tokenLiteral).toEqual("5")
  }

  Test.report()
}

func expectParsed(_ input: String, _ expectedNumStatements: Int) -> [Statement]? {
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
