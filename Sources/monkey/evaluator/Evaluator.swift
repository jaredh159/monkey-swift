func eval(_ node: Node?) -> Object? {
  guard let node = node else {
    return nil
  }
  switch node {
    case let program as ProgramProtocol:
      return evalProgram(program)
    case let exprStmt as ExpressionStatement:
      return eval(exprStmt.expression)
    case let intLit as IntegerLiteral:
      return Integer(value: intLit.value)
    case let boolLit as BooleanLiteral:
      return Boolean.from(boolLit.value)
    case let prefixExp as PrefixExpression:
      let right = eval(prefixExp.right)
      return evalPrefixExpression(operator: prefixExp.operator, rhs: right)
    case let infixExp as InfixExpression:
      let right = eval(infixExp.right)
      let left = eval(infixExp.left)
      return evalInfixExpression(operator: infixExp.operator, lhs: left, rhs: right)
    case let blockStmt as BlockStatement:
      return evalBlockStatement(blockStmt)
    case let ifExp as IfExpression:
      return evalIfExpression(ifExp)
    case let returnStmt as ReturnStatement:
      if let val = eval(returnStmt.returnValue) {
        return ReturnValue(value: val)
      } else {
        return nil
      }
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

// there's probably a more swifty way to do this with one giant pattern-matching
// switch statement, but i can't figure it out...
func evalInfixExpression(operator op: String, lhs: Object?, rhs: Object?) -> Object {
  if let lhs = lhs as? Integer, let rhs = rhs as? Integer {
    return evalIntegerInfixExpression(operator: op, lhs: lhs, rhs: rhs)
  }
  if let lhs = lhs as? Boolean, let rhs = rhs as? Boolean {
    switch op {
      case "!=":
        return Boolean.from(lhs !== rhs)
      case "==":
        return Boolean.from(lhs === rhs)
      default:
        return Null
    }
  }
  return Null
}

func evalIntegerInfixExpression(operator: String, lhs: Integer, rhs: Integer) -> Object {
  switch `operator` {
    case "+":
      return Integer(value: lhs.value + rhs.value)
    case "-":
      return Integer(value: lhs.value - rhs.value)
    case "*":
      return Integer(value: lhs.value * rhs.value)
    case "/":
      return Integer(value: lhs.value / rhs.value)
    case "<":
      return Boolean.from(lhs.value < rhs.value)
    case ">":
      return Boolean.from(lhs.value > rhs.value)
    case "==":
      return Boolean.from(lhs.value == rhs.value)
    case "!=":
      return Boolean.from(lhs.value != rhs.value)
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
    case Boolean.false:
      return .true
    case Boolean.true:
      return .false
    case Null:
      return .true
    default:
      return .false
  }
}

func evalIfExpression(_ ifExp: IfExpression) -> Object? {
  let condition = eval(ifExp.condition)
  if isTruthy(condition) {
    return eval(ifExp.consequence)
  } else if let alt = ifExp.alternative {
    return eval(alt)
  } else {
    return Null
  }
}

func isTruthy(_ obj: Object?) -> Bool {
  switch obj {
    case Boolean.false:
      return false
    case Boolean.true:
      return true
    case Null:
      return false
    default:
      return true
  }
}

func evalProgram(_ program: ProgramProtocol) -> Object? {
  var result: Object? = nil
  for statement in program.statements {
    result = eval(statement)
    if let returnValue = result as? ReturnValue {
      return returnValue.value
    }
  }
  return result
}

func evalBlockStatement(_ block: BlockStatement) -> Object? {
  var result: Object? = nil
  for statement in block.statements {
    result = eval(statement)
    if let _ = result as? ReturnValue {
      return result
    }
  }
  return result
}
