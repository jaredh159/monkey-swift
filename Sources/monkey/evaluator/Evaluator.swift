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
    case let prefixExp as PrefixExpression:
      let right = eval(prefixExp.right)
      return evalPrefixExpression(operator: prefixExp.operator, rhs: right)
    default:
      return nil
  }
}

func evalPrefixExpression(operator: String, rhs: Object?) -> Object {
  switch `operator` {
    case "!":
      return evalBangOperatorExpression(rhs: rhs)
    case "-":
      return evalMinusPrefixOperatorExpression(rhs: rhs)
    default:
      return Null
  }
}

func evalMinusPrefixOperatorExpression(rhs: Object?) -> Object {
  guard let int = rhs as? Integer else {
    return Null
  }
  return Integer(value: -int.value)
}

func evalBangOperatorExpression(rhs: Object?) -> Boolean {
  switch rhs {
    case let bool as Boolean where bool === Boolean.false:
      return .true
    case let bool as Boolean where bool === Boolean.true:
      return .false
    case _ as NullObject:
      return .true
    default:
      return .false
  }
}

func evalStatements(_ statements: [Statement]) -> Object? {
  var result: Object? = nil
  for statement in statements {
    result = eval(statement)
  }
  return result
}
