class Lexer {
  private var position: Int = -1
  private var readPosition: Int = 0
  private var ch: Character = "\0"
  private let input: String

  private static var keywords: [String: TokenType] = [
    "fn": .FUNCTION,
    "let": .LET,
    "true": .TRUE,
    "false": .FALSE,
    "if": .IF,
    "else": .ELSE,
    "return": .RETURN,
  ]

  init(_ input: String) {
    self.input = input
    readChar()
  }

  func nextToken() -> Token {
    defer { readChar() }
    skipWhitespace()
    switch ch {
      case "=" where peekChar() == "=":
        return Token(type: .EQ, literal: "=" + String(readChar()))
      case "=":
        return Token(type: .ASSIGN, literal: ch)
      case ";":
        return Token(type: .SEMICOLON, literal: ch)
      case "(":
        return Token(type: .LPAREN, literal: ch)
      case ")":
        return Token(type: .RPAREN, literal: ch)
      case ",":
        return Token(type: .COMMA, literal: ch)
      case "+":
        return Token(type: .PLUS, literal: ch)
      case "{":
        return Token(type: .LBRACE, literal: ch)
      case "}":
        return Token(type: .RBRACE, literal: ch)
      case "!" where peekChar() == "=":
        return Token(type: .NOT_EQ, literal: "!" + String(readChar()))
      case "!":
        return Token(type: .BANG, literal: ch)
      case "*":
        return Token(type: .ASTERISK, literal: ch)
      case "/":
        return Token(type: .SLASH, literal: ch)
      case "-":
        return Token(type: .MINUS, literal: ch)
      case "<":
        return Token(type: .LT, literal: ch)
      case ">":
        return Token(type: .GT, literal: ch)
      case "\0":
        return Token(type: .EOF, literal: "")
      case "[":
        return Token(type: .LBRACKET, literal: ch)
      case "]":
        return Token(type: .RBRACKET, literal: ch)
      case "\"":
        return Token(type: .STRING, literal: readString())
      case let digit where digit.isNumber:
        return Token(type: .INT, literal: readNumber())
      case let letter where isLetter(letter):
        let literal = readIdentifier()
        return Token(type: identType(literal), literal: literal)
      default:
        return Token(type: .ILLEGAL, literal: "")
    }
  }

  @discardableResult
  private func readChar(advance: Bool = true) -> Character {
    var read: Character = "\0"
    if readPosition < input.count {
      read = input[input.index(input.startIndex, offsetBy: readPosition)]
    }

    if advance {
      ch = read
      position += 1
      readPosition += 1
    }

    return read
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

  private func readString() -> String {
    if peekChar() == "\"" {
      readChar()
      return ""
    }
    var str = String(readChar())
    while peekChar() != "\"" {
      readChar()
      str.append(ch)
    }
    readChar()
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
