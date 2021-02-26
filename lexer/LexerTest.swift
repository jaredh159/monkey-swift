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
      !-/*5;
      5 < 10 > 5;
      true
      false
      if 
      else
      return
      ==
      !=
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
      (.BANG, "!"),
      (.MINUS, "-"),
      (.SLASH, "/"),
      (.ASTERISK, "*"),
      (.INT, "5"),
      (.SEMICOLON, ";"),
      (.INT, "5"),
      (.LT, "<"),
      (.INT, "10"),
      (.GT, ">"),
      (.INT, "5"),
      (.SEMICOLON, ";"),
      (.TRUE, "true"),
      (.FALSE, "false"),
      (.IF, "if"),
      (.ELSE, "else"),
      (.RETURN, "return"),
      (.EQ, "=="),
      (.NOT_EQ, "!="),
      (.EOF, ""),
    ]

    let lexer = Lexer(input)

    for (expectedType, expectedLiteral) in tests {
      let token = lexer.nextToken()
      // print(token)
      expect(token.type).toEqual(expectedType)
      expect(token.literal).toEqual(expectedLiteral)
    }
  }

  Test.report()
}
