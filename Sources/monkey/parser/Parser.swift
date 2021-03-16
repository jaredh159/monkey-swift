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

  func parseExpressionStatement() -> ExpressionStatement? {
    let startToken = curToken
    guard let expression = parseExpression(precedence: .LOWEST) else {
      return nil
    }
    if peekTokenIs(.SEMICOLON) {
      nextToken()
    }
    return ExpressionStatement(token: startToken, expression: expression)
  }

  func parseExpression(precedence: Precedence) -> Expression? {
    guard let prefixFn = Parselet.prefixFns[curToken.type] else {
      errors.append("no prefix parse function for \(curToken) found")
      return nil
    }

    guard var leftExp = prefixFn() else {
      return nil
    }

    while !peekTokenIs(.SEMICOLON) && precedence < peekPrecedence() {
      if let infix = Parselet.infixFns[peekToken.type] {
        nextToken()
        guard let nextLeft = infix(leftExp) else {
          return nil
        }
        leftExp = nextLeft
      } else {
        return leftExp
      }
    }

    return leftExp
  }

  func parseReturnStatement() -> ReturnStatement? {
    let startToken = curToken
    nextToken()
    guard let returnValue = parseExpression(precedence: .LOWEST) else {
      return nil
    }
    if peekTokenIs(.SEMICOLON) {
      nextToken()
    }
    return ReturnStatement(token: startToken, returnValue: returnValue)
  }

  func parseLetStatement() -> LetStatement? {
    let startToken = curToken
    if !expectPeek(.IDENT) {
      return nil
    }
    let name = Identifier(token: curToken, value: curToken.literal)
    if !expectPeek(.ASSIGN) {
      return nil
    }
    nextToken()
    guard let value = parseExpression(precedence: .LOWEST) else {
      return nil
    }
    if peekTokenIs(.SEMICOLON) {
      nextToken()
    }
    return LetStatement(token: startToken, name: name, value: value)
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

  func parseBooleanLiteral() -> BooleanLiteral {
    return BooleanLiteral(token: curToken, value: curToken.type == .TRUE)
  }

  func parsePrefixExpression() -> PrefixExpression? {
    let startToken = curToken
    nextToken()
    guard let right = parseExpression(precedence: .PREFIX) else {
      return nil
    }
    return PrefixExpression(token: startToken, operator: startToken.literal, right: right)
  }

  func parseInfixExpression(_ left: Expression) -> InfixExpression? {
    let startToken = curToken
    let precedence = curPrecedence()
    nextToken()
    guard let right = parseExpression(precedence: precedence) else {
      return nil
    }
    return InfixExpression(
      token: startToken, left: left, operator: startToken.literal, right: right)
  }

  func parseGroupedExpression() -> Expression? {
    nextToken()
    let exp = parseExpression(precedence: .LOWEST)
    guard expectPeek(.RPAREN) else {
      return nil
    }
    return exp
  }

  func parseIfExpression() -> Expression? {
    let startToken = curToken
    guard expectPeek(.LPAREN) else {
      return nil
    }
    nextToken()
    guard let condition = parseExpression(precedence: .LOWEST) else {
      return nil
    }
    guard expectPeek(.RPAREN) else {
      return nil
    }
    guard expectPeek(.LBRACE) else {
      return nil
    }
    let consequence = parseBlockStatement()
    var expression = IfExpression(token: startToken, condition: condition, consequence: consequence)
    if peekTokenIs(.ELSE) {
      nextToken()
      guard expectPeek(.LBRACE) else {
        return nil
      }
      expression.alternative = parseBlockStatement()
    }
    return expression
  }

  func parseStringLiteral() -> StringLiteral {
    return StringLiteral(token: curToken)
  }

  func parseBlockStatement() -> BlockStatement {
    var block = BlockStatement(token: curToken)
    nextToken()
    while !curTokenIs(.RBRACE) && !curTokenIs(.EOF) {
      if let stmt = parseStatement() {
        block.statements.append(stmt)
      }
      nextToken()
    }
    return block
  }

  func parseFunctionLiteral() -> FunctionLiteral? {
    let startToken = curToken
    guard expectPeek(.LPAREN) else {
      return nil
    }
    let parameters = parseFunctionParameters()
    guard expectPeek(.LBRACE) else {
      return nil
    }
    let body = parseBlockStatement()
    return FunctionLiteral(token: startToken, parameters: parameters, body: body)
  }

  func parseFunctionParameters() -> [Identifier] {
    var identifiers: [Identifier] = []
    if peekTokenIs(.RPAREN) {
      nextToken()
      return identifiers
    }
    nextToken()
    identifiers.append(Identifier(token: curToken, value: curToken.literal))
    while peekTokenIs(.COMMA) {
      nextToken()
      nextToken()
      identifiers.append(Identifier(token: curToken, value: curToken.literal))
    }
    _ = expectPeek(.RPAREN)
    return identifiers
  }

  func parseCallExpression(function: Expression) -> CallExpression {
    let initialToken = curToken
    let arguments = parseCallArguments()
    return CallExpression(token: initialToken, function: function, arguments: arguments)
  }

  func parseCallArguments() -> [Expression] {
    var args: [Expression] = []
    if peekTokenIs(.RPAREN) {
      return args
    }
    nextToken()
    if let expr = parseExpression(precedence: .LOWEST) {
      args.append(expr)
    }
    while peekTokenIs(.COMMA) {
      nextToken()
      nextToken()
      if let expr = parseExpression(precedence: .LOWEST) {
        args.append(expr)
      }
    }
    _ = expectPeek(.RPAREN)
    return args
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
    Parselet.register(prefix: self.parseBooleanLiteral, .TRUE)
    Parselet.register(prefix: self.parseBooleanLiteral, .FALSE)
    Parselet.register(prefix: self.parseGroupedExpression, .LPAREN)
    Parselet.register(prefix: self.parseIfExpression, .IF)
    Parselet.register(prefix: self.parseFunctionLiteral, .FUNCTION)
    Parselet.register(prefix: self.parseStringLiteral, .STRING)
    Parselet.register(infix: self.parseInfixExpression, .PLUS)
    Parselet.register(infix: self.parseInfixExpression, .MINUS)
    Parselet.register(infix: self.parseInfixExpression, .SLASH)
    Parselet.register(infix: self.parseInfixExpression, .ASTERISK)
    Parselet.register(infix: self.parseInfixExpression, .EQ)
    Parselet.register(infix: self.parseInfixExpression, .NOT_EQ)
    Parselet.register(infix: self.parseInfixExpression, .LT)
    Parselet.register(infix: self.parseInfixExpression, .GT)
    Parselet.register(infix: self.parseCallExpression, .LPAREN)
  }

  private func nextToken() {
    curToken = peekToken
    peekToken = l.nextToken()
  }

  private func peekPrecedence() -> Precedence {
    return Precedence(ofToken: peekToken)
  }

  private func curPrecedence() -> Precedence {
    return Precedence(ofToken: curToken)
  }
}
