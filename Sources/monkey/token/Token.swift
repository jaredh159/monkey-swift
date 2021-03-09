enum TokenType: String, CustomStringConvertible {
  case ILLEGAL
  case EOF
  case IDENT
  case INT
  case ASSIGN
  case PLUS
  case COMMA
  case SEMICOLON
  case LPAREN
  case RPAREN
  case LBRACE
  case RBRACE
  case FUNCTION
  case LET
  case MINUS
  case BANG
  case ASTERISK
  case SLASH
  case LT
  case GT
  case TRUE
  case FALSE
  case IF
  case ELSE
  case RETURN
  case EQ
  case NOT_EQ

  var description: String {
    return "." + self.rawValue
  }
}

struct Token {
  let type: TokenType
  let literal: String

  init(type: TokenType, literal: String) {
    self.type = type
    self.literal = literal
  }

  init(type: TokenType, literal: Character) {
    self.type = type
    self.literal = String(literal)
  }
}
