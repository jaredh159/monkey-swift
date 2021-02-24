

func main() -> Void {
  Test.reset(suiteName: "LexerTest")

  test("next token") {
    let input = "=+(){},;"
    let tests: [(TokenType, String)] = [
      (.ASSIGN, "="),
      (.PLUS, "+"),
      (.LPAREN, "("),
      (.RPAREN, ")"),
      (.LBRACE, "{"),
      (.RBRACE, "}"),
      (.COMMA, ","),
      (.SEMICOLON, ";"),
      (.EOF, ""),
    ]

    let lexer = Lexer(input)

    for (expectedType, expectedLiteral) in tests {
      let token = lexer.nextToken()
      expect(token.type).toEqual(expectedType)
      expect(token.literal).toEqual(expectedLiteral)
    }
  }

  Test.report()
}

