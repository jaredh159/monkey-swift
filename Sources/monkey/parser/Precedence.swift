enum Precedence: Int, Comparable {
  case LOWEST = 0
  case EQUALS
  case LESSGREATER
  case SUM
  case PRODUCT
  case PREFIX
  case CALL
  case INDEX

  init(ofToken token: Token) {
    switch token.type {
      case .EQ:
        self = .EQUALS
      case .NOT_EQ:
        self = .EQUALS
      case .LT:
        self = .LESSGREATER
      case .GT:
        self = .LESSGREATER
      case .PLUS:
        self = .SUM
      case .MINUS:
        self = .SUM
      case .SLASH:
        self = .PRODUCT
      case .ASTERISK:
        self = .PRODUCT
      case .LPAREN:
        self = .CALL
      case .LBRACKET:
        self = .INDEX
      default:
        self = .LOWEST
    }
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }
}
