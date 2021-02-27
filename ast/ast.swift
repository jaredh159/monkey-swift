protocol Node {
  func tokenLiteral() -> String
}

protocol HasToken: Node {
  var token: Token { get }
}

extension HasToken {
  func tokenLiteral() -> String {
    return self.token.literal
  }
}

protocol Statement: Node {}
protocol Expression: Node {}

protocol ProgramProtocol: Node {
  var statements: [Statement] { get set }
}

struct Program: ProgramProtocol {
  var statements: [Statement] = []

  func tokenLiteral() -> String {
    if let firstStatement = statements.first {
      return firstStatement.tokenLiteral()
    } else {
      return ""
    }
  }
}

struct LetStatement: HasToken, Statement {
  var token: Token
  var name: Identifier?
  var value: Expression?
}

struct Identifier: HasToken, Expression {
  var token: Token
  let value: String
}
