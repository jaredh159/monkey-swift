class Parser {
  private let l: Lexer
  private var curToken: Token
  private var peekToken: Token
  var errors: [String] = []

  func parseProgram() -> ProgramProtocol {
    var program = Program()
    while curToken.type != .EOF {
      if let statement = parseStatement() {
        program.statements.append(statement)
      }
      nextToken()
    }
    return program
  }

  func parseStatement() -> Statement? {
    switch curToken.type {
      case .LET:
        return parseLetStatement()
      default:
        return nil
    }
  }

  func parseLetStatement() -> LetStatement? {
    var stmt = LetStatement(token: curToken)

    if !expectPeek(.IDENT) {
      return nil
    }

    stmt.name = Identifier(token: curToken, value: curToken.literal)

    if !expectPeek(.ASSIGN) {
      return nil
    }

    // skip parsing expressions for now
    while !curTokenIs(.SEMICOLON) {
      nextToken()
    }

    return stmt
  }

  func curTokenIs(_ tokenType: TokenType) -> Bool {
    return curToken.type == tokenType
  }

  func peekTokenIs(_ tokenType: TokenType) -> Bool {
    return peekToken.type == tokenType
  }

  func expectPeek(_ tokenType: TokenType) -> Bool {
    if peekTokenIs(tokenType) {
      nextToken()
      return true
    }
    peekError(tokenType)
    return false
  }

  func peekError(_ tokenType: TokenType) {
    let err = "expected next token to be \(tokenType), got \(peekToken.type) instead"
    errors.append(err)
  }

  init(_ lexer: Lexer) {
    l = lexer

    // temp tokens so we don't need them to be optionals
    curToken = Token(type: .EOF, literal: "")
    peekToken = Token(type: .EOF, literal: "")

    // read first two tokens
    nextToken()
    nextToken()
  }

  private func nextToken() {
    curToken = peekToken
    peekToken = l.nextToken()
  }
}
