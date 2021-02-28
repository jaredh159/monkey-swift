protocol Node {
  var tokenLiteral: String { get }
  var string: String { get }
}

protocol HasToken: Node {
  var token: Token { get }
}

extension HasToken {
  var tokenLiteral: String { self.token.literal }
}

protocol Statement: Node {}
protocol Expression: Node {}

protocol ProgramProtocol: Node {
  var statements: [Statement] { get set }
}

struct Program: ProgramProtocol {
  var statements: [Statement] = []

  var tokenLiteral: String {
    if let firstStatement = statements.first {
      return firstStatement.tokenLiteral
    } else {
      return ""
    }
  }

  var string: String {
    statements.map { $0.string }.joined()
  }
}

struct LetStatement: HasToken, Statement {
  var token: Token
  var name: Identifier?
  var value: Expression?

  var string: String {
    "\(tokenLiteral) \(name?.string ?? "") = \(value?.string ?? "");"
  }
}

struct Identifier: HasToken, Expression {
  var token: Token
  let value: String
  var string: String { value }
}

struct ReturnStatement: HasToken, Statement {
  var token: Token
  var returnValue: Expression?

  var string: String {
    "\(tokenLiteral) \(returnValue?.string ?? "");"
  }
}

struct ExpressionStatement: HasToken, Statement {
  var token: Token
  var expression: Expression?

  var string: String {
    expression?.string ?? ""
  }
}
