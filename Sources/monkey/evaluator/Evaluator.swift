func eval(_ node: Node?) -> Object? {
  guard let node = node else {
    return nil
  }
  switch node {
    case let program as ProgramProtocol:
      return evalStatements(program.statements)
    case let exprStmt as ExpressionStatement:
      return eval(exprStmt.expression)
    case let intLit as IntegerLiteral:
      return Integer(value: intLit.value)
    case let boolLit as BooleanLiteral:
      return boolLit.value ? Boolean.true : Boolean.false
    default:
      return nil
  }
}

func evalStatements(_ statements: [Statement]) -> Object? {
  var result: Object? = nil
  for statement in statements {
    result = eval(statement)
  }
  return result
}
