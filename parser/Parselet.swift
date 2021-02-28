struct Parselet {
  typealias Prefix = () -> Expression?
  typealias Infix = (_ lhs: Expression) -> Expression?

  static var prefixFns: [TokenType: Prefix] = [:]
  static var infixFns: [TokenType: Infix] = [:]

  static func register(prefix: @escaping Prefix, _ tokenType: TokenType) {
    prefixFns[tokenType] = `prefix`
  }

  static func register(infix: @escaping Infix, _ tokenType: TokenType) {
    infixFns[tokenType] = `infix`
  }
}
