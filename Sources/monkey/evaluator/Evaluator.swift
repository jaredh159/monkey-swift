func eval(_ node: Node?) -> Object {
  guard let node = node else {
    return Error("unexpected nil node")
  }
  switch node {
    case let program as ProgramProtocol:
      return evalStatements(program.statements)
    case let exprStmt as ExpressionStatement:
      return eval(exprStmt.expression)
    case let intLit as IntegerLiteral:
      return Integer(value: intLit.value)
    default:
      return Error("unexpected node type")
  }
}

func evalStatements(_ statements: [Statement]) -> Object {
  var result: Object = Null()
  for statement in statements {
    result = eval(statement)
  }
  return result
}
