protocol Node: CustomStringConvertible {
  var tokenLiteral: String { get }
  var string: String { get }
}

extension Node {
  var description: String { string }
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
  var name: Identifier
  var value: Expression

  var string: String {
    "\(tokenLiteral) \(name) = \(value);"
  }
}

struct Identifier: HasToken, Expression {
  var token: Token
  let value: String
  var string: String { value }
}

struct ReturnStatement: HasToken, Statement {
  var token: Token
  var returnValue: Expression

  var string: String {
    "\(tokenLiteral) \(returnValue);"
  }
}

struct ExpressionStatement: HasToken, Statement {
  var token: Token
  var expression: Expression
  var string: String { expression.string }
}

struct StringLiteral: HasToken, Expression {
  var token: Token
  var value: String { tokenLiteral }
  var string: String { tokenLiteral }
}

struct ArrayLiteral: HasToken, Expression {
  var token: Token
  var elements: [Expression]
  var string: String {
    "[\(elements.map { $0.string }.joined(separator: ", "))]"
  }
}

struct IntegerLiteral: HasToken, Expression {
  var token: Token
  var value: Int
  var string: String { tokenLiteral }
}

struct PrefixExpression: HasToken, Expression {
  var token: Token
  var `operator`: String
  var right: Expression
  var string: String { "(\(self.operator)\(right))" }
}

struct InfixExpression: HasToken, Expression {
  var token: Token
  var left: Expression
  var `operator`: String
  var right: Expression
  var string: String { "(\(left) \(self.operator) \(right))" }
}

struct IndexExpression: HasToken, Expression {
  var token: Token
  var left: Expression
  var index: Expression
  var string: String { "(\(left)[\(index)])" }
}

struct BooleanLiteral: HasToken, Expression {
  var token: Token
  var value: Bool
  var string: String { tokenLiteral }
}

struct IfExpression: HasToken, Expression {
  var token: Token
  var condition: Expression
  var consequence: BlockStatement
  var alternative: BlockStatement?
  var string: String {
    var alt = ""
    if let alternative = alternative {
      alt = "else \(alternative)"
    }
    return "if\(condition) \(consequence)\(alt)"
  }
}

struct BlockStatement: HasToken, Statement {
  var token: Token
  var statements: [Statement] = []

  var string: String {
    statements.map { $0.string }.joined()
  }
}

struct FunctionLiteral: HasToken, Expression {
  var token: Token
  var parameters: [Identifier] = []
  var body: BlockStatement
  var name: String?

  var string: String {
    let params = parameters.map { $0.string }.joined(separator: ", ")
    return "\(name == nil ? "" : "<\(name!)>")\(tokenLiteral) (\(params)) \(body)"
  }
}

struct CallExpression: HasToken, Expression {
  var token: Token
  var function: Expression  // Identifier || FunctionLiteral
  var arguments: [Expression] = []

  var string: String {
    let args = arguments.map { $0.string }.joined(separator: ", ")
    return "\(function)(\(args))"
  }
}

struct HashLiteral: HasToken, Expression {
  var token: Token
  var pairs: [(key: Expression, value: Expression)]

  var string: String {
    "{\(pairs.map { "\($0):\($1)" }.joined(separator: ", "))}"
  }
}
