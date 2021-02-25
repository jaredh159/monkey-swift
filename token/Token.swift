public enum TokenType: String {
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
}

public struct Token {
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
