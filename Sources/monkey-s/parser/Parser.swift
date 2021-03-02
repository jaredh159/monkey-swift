enum Precedence: Int {
  case LOWEST = 0
  case EQUALS
  case LESSGREATER
  case SUM
  case PRODUCT
  case PREFIX
  case CALL
}

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
      case .RETURN:
        return parseReturnStatement()
      default:
        return parseExpressionStatement()
    }
  }

  func parseExpressionStatement() -> ExpressionStatement {
    var stmt = ExpressionStatement(token: curToken)
    stmt.expression = parseExpression(precedence: .LOWEST)
    if peekTokenIs(.SEMICOLON) {
      nextToken()
    }
    return stmt
  }

  func parseExpression(precedence: Precedence) -> Expression? {
    guard let prefixFn = Parselet.prefixFns[curToken.type] else {
      errors.append("no prefix parse function for \(curToken) found")
      return nil
    }
    let leftExp = prefixFn()
    return leftExp
  }

  func parseReturnStatement() -> ReturnStatement? {
    let stmt = ReturnStatement(token: curToken)
    nextToken()

    // skip parsing expressions for now
    while !curTokenIs(.SEMICOLON) {
      nextToken()
    }

    return stmt
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

  func parseIdentifier() -> Identifier {
    return Identifier(token: curToken, value: curToken.literal)
  }

  func parseIntegerLiteral() -> IntegerLiteral? {
    guard let int = Int(curToken.literal) else {
      errors.append("could not parse \(curToken.literal) as integer")
      return nil
    }
    return IntegerLiteral(token: curToken, value: int)
  }

  func parsePrefixExpression() -> PrefixExpression {
    var expr = PrefixExpression(token: curToken, operator: curToken.literal)
    nextToken()
    expr.right = parseExpression(precedence: .PREFIX)
    return expr
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

    Parselet.register(prefix: self.parseIdentifier, .IDENT)
    Parselet.register(prefix: self.parseIntegerLiteral, .INT)
    Parselet.register(prefix: self.parsePrefixExpression, .BANG)
    Parselet.register(prefix: self.parsePrefixExpression, .MINUS)
  }

  private func nextToken() {
    curToken = peekToken
    peekToken = l.nextToken()
  }
}
