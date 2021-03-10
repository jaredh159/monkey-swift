func testEval() {
  Test.reset(suiteName: "EvaluatorTest")

  test("eval integer expression") {
    let cases = [
      ("5", 5),
      ("10", 10),
    ]
    cases.forEach { (input, expected) in
      let evaluated = testEval(input)
      expect(evaluated).toBeObject(int: expected)
    }
  }

  Test.report()
}

func testEval(_ input: String) -> Object? {
  let parser = Parser(Lexer(input))
  let program = parser.parseProgram()
  return eval(program)
}
