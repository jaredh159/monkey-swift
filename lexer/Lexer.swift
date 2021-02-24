class Lexer {
  private let input: String

  init(_ input: String) {
    self.input = input
  }

  func nextToken() -> Token {
    return Token(type: .ASSIGN, literal: "LOL")
  }
}
