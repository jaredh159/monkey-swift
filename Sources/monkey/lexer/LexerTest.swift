func testLexer() -> Bool {
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
      "foobar"
      "foo bar"
      [1, 2]
      {"foo": "bar"}
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
      (.STRING, "foobar"),
      (.STRING, "foo bar"),
      (.LBRACKET, "["),
      (.INT, "1"),
      (.COMMA, ","),
      (.INT, "2"),
      (.RBRACKET, "]"),
      (.LBRACE, "{"),
      (.STRING, "foo"),
      (.COLON, ":"),
      (.STRING, "bar"),
      (.RBRACE, "}"),
      (.EOF, ""),
    ]

    let lexer = Lexer(input)

    for (expectedType, expectedLiteral) in tests {
      let token = lexer.nextToken()
      expect(token.type).toEqual(expectedType)
      expect(token.literal).toEqual(expectedLiteral)
    }
  }

  return Test.report()
}
