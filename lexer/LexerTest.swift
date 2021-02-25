func main() {
  Test.reset(suiteName: "LexerTest")

  test("next token") {
    let input = """
      let five = 5;
      let ten = 10;
      let add = fn(x, y) {
        x + y;
      };
      let result = add(five, ten);
      """

    let tests: [(TokenType, String)] = [
      (.LET, "let"),
      (.IDENT, "five"),
      (.ASSIGN, "="),
      (.INT, "5"),
      (.SEMICOLON, ";"),
      (.LET, "let"),
      (.IDENT, "ten"),
      (.ASSIGN, "="),
      (.INT, "10"),
      (.SEMICOLON, ";"),
      (.LET, "let"),
      (.IDENT, "add"),
      (.ASSIGN, "="),
      (.FUNCTION, "fn"),
      (.LPAREN, "("),
      (.IDENT, "x"),
      (.COMMA, ","),
      (.IDENT, "y"),
      (.RPAREN, ")"),
      (.LBRACE, "{"),
      (.IDENT, "x"),
      (.PLUS, "+"),
      (.IDENT, "y"),
      (.SEMICOLON, ";"),
      (.RBRACE, "}"),
      (.SEMICOLON, ";"),
      (.LET, "let"),
      (.IDENT, "result"),
      (.ASSIGN, "="),
      (.IDENT, "add"),
      (.LPAREN, "("),
      (.IDENT, "five"),
      (.COMMA, ","),
      (.IDENT, "ten"),
      (.RPAREN, ")"),
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
