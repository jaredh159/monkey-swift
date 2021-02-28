func main() {
  Test.reset(suiteName: "AstTest")

  test("string") {
    let myVar = Identifier(token: Token(type: .IDENT, literal: "myVar"), value: "myVar")
    let anotherVar = Identifier(
      token: Token(type: .IDENT, literal: "anotherVar"), value: "anotherVar")
    var letStatement = LetStatement(token: Token(type: .LET, literal: "let"))
    letStatement.name = myVar
    letStatement.value = anotherVar
    let program = Program(statements: [letStatement])

    expect(program.string).toEqual("let myVar = anotherVar;")
  }

  Test.report()
}
