class Lexer {
  private var position: Int = -1
  private var readPosition: Int = 0
  private var ch: Character = "\0"
  private let input: String

  private static var keywords: [String: TokenType] = [
    "fn": .FUNCTION,
    "let": .LET,
  ]

  init(_ input: String) {
    self.input = input
    readChar()
  }

  func nextToken() -> Token {
    var tok = Token(type: .ILLEGAL, literal: "")
    skipWhitespace()
    switch ch {
      case "=":
        tok = Token(type: .ASSIGN, literal: ch)
      case ";":
        tok = Token(type: .SEMICOLON, literal: ch)
      case "(":
        tok = Token(type: .LPAREN, literal: ch)
      case ")":
        tok = Token(type: .RPAREN, literal: ch)
      case ",":
        tok = Token(type: .COMMA, literal: ch)
      case "+":
        tok = Token(type: .PLUS, literal: ch)
      case "{":
        tok = Token(type: .LBRACE, literal: ch)
      case "}":
        tok = Token(type: .RBRACE, literal: ch)
      case "\0":
        tok = Token(type: .EOF, literal: "")
      case let digit where digit.isNumber:
        tok = Token(type: .INT, literal: readNumber())
      case let letter where isLetter(letter):
        let literal = readIdentifier()
        tok = Token(type: identType(literal), literal: literal)
      default:
        tok = Token(type: .ILLEGAL, literal: "")
    }
    readChar()
    return tok
  }

  @discardableResult
  private func readChar(advance: Bool = true) -> Character {
    if readPosition >= input.count {
      ch = "\0"
    } else {
      ch = input[input.index(input.startIndex, offsetBy: readPosition)]
    }
    if advance {
      position += 1
      readPosition += 1
    }
    return ch
  }

  private func peekChar() -> Character {
    return readChar(advance: false)
  }

  private func readIdentifier() -> String {
    var str = String(ch)
    while isLetter(peekChar()) {
      readChar()
      str.append(ch)
    }
    return str
  }

  private func readNumber() -> String {
    var str = String(ch)
    while peekChar().isNumber {
      readChar()
      str.append(ch)
    }
    return str
  }

  private func isLetter(_ char: Character) -> Bool {
    return char.isLetter || char == "_"
  }

  private func identType(_ ident: String) -> TokenType {
    return Lexer.keywords[ident] ?? .IDENT
  }

  private func skipWhitespace() {
    while ch.isWhitespace {
      readChar()
    }
  }
}
