func eval(_ node: Node?, _ env: Environment) -> Object {
  switch node {
    case let program as ProgramProtocol:
      return evalProgram(program, env)
    case let exprStmt as ExpressionStatement:
      return eval(exprStmt.expression, env)
    case let intLit as IntegerLiteral:
      return Integer(value: intLit.value)
    case let boolLit as BooleanLiteral:
      return Boolean.from(boolLit.value)
    case let strLit as StringLiteral:
      return StringObject(value: strLit.value)
    case let prefixExp as PrefixExpression:
      let right = eval(prefixExp.right, env)
      if right.isError {
        return right
      }
      return evalPrefixExpression(op: prefixExp.operator, rhs: right)
    case let infixExp as InfixExpression:
      let right = eval(infixExp.right, env)
      if right.isError {
        return right
      }
      let left = eval(infixExp.left, env)
      if left.isError {
        return left
      }
      return evalInfixExpression(operator: infixExp.operator, lhs: left, rhs: right)
    case let blockStmt as BlockStatement:
      return evalBlockStatement(blockStmt, env)
    case let ifExp as IfExpression:
      return evalIfExpression(ifExp, env)
    case let returnStmt as ReturnStatement:
      let returnValue = eval(returnStmt.returnValue, env)
      if returnValue.isError {
        return returnValue
      }
      return ReturnValue(value: returnValue)
    case let letStmt as LetStatement:
      let val = eval(letStmt.value, env)
      if val.isError {
        return val
      }
      return env.set(letStmt.name.value, val)
    case let identifier as Identifier:
      return evalIdentifier(identifier, env)
    case let fnLit as FunctionLiteral:
      return Function(parameters: fnLit.parameters, body: fnLit.body, env: env)
    case let callExp as CallExpression:
      let function = eval(callExp.function, env)
      if function.isError {
        return function
      }
      let args = evalExpressions(callExp.arguments, env)
      if args.count == 1 && args.first.isError {
        return args.first!
      }
      return applyFunction(function, args)
    default:
      return Error("unexpected node type \(node?.string ?? "nil")")
  }
}

func applyFunction(_ obj: Object, _ args: [Object]) -> Object {
  guard let fn = obj as? Function else {
    return Error("not a function: \(obj.type)")
  }
  let extendedEnv = extendFunctionEnv(fn, args)
  let evaluated = eval(fn.body, extendedEnv)
  return unwrapReturnValue(evaluated)
}

func unwrapReturnValue(_ obj: Object) -> Object {
  if let returnValue = obj as? ReturnValue {
    return returnValue.value
  }
  return obj
}

func extendFunctionEnv(_ fn: Function, _ args: [Object]) -> Environment {
  let env = Environment(enclosedBy: fn.env)
  for (param, arg) in zip(fn.parameters, args) {
    env.set(param.value, arg)
  }
  return env
}

func evalExpressions(_ expressions: [Expression], _ env: Environment) -> [Object] {
  var results: [Object] = []
  for expression in expressions {
    let result = eval(expression, env)
    if result.isError {
      return [result]
    } else {
      results.append(result)
    }
  }
  return results
}

func evalIdentifier(_ ident: Identifier, _ env: Environment) -> Object {
  guard let value = env.get(ident.value) else {
    return Error("identifier not found: \(ident.value)")
  }
  return value
}

func evalPrefixExpression(op: String, rhs: Object?) -> Object {
  switch op {
    case "!":
      return evalBangOperatorExpression(rhs: rhs)
    case "-":
      return evalMinusPrefixOperatorExpression(rhs: rhs)
    default:
      return Error("unknown operator: \(op)\(rhs.type)")
  }
}

// there's probably a more swifty way to do this with one giant pattern-matching
// switch statement, but i can't figure it out...
func evalInfixExpression(operator op: String, lhs: Object?, rhs: Object?) -> Object {
  if let lhs = lhs as? Integer, let rhs = rhs as? Integer {
    return evalIntegerInfixExpression(op: op, lhs: lhs, rhs: rhs)
  }

  if let lhs = lhs as? Boolean, let rhs = rhs as? Boolean {
    switch op {
      case "!=":
        return Boolean.from(lhs !== rhs)
      case "==":
        return Boolean.from(lhs === rhs)
      default:
        return Error("unknown operator: \(lhs.type) \(op) \(rhs.type)")
    }
  }

  if let lhs = lhs as? StringObject, let rhs = rhs as? StringObject {
    guard op == "+" else {
      return Error("unknown operator: \(lhs.type) \(op) \(rhs.type)")
    }
    return StringObject(value: lhs.value + rhs.value)
  }

  return Error("type mismatch: \(lhs.type) \(op) \(rhs.type)")
}

func evalIntegerInfixExpression(op: String, lhs: Integer, rhs: Integer) -> Object {
  switch op {
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
      return Error("unknown operator: \(lhs.type) \(op) \(rhs.type)")
  }
}

func evalMinusPrefixOperatorExpression(rhs: Object?) -> Object {
  guard let int = rhs as? Integer else {
    return Error("unknown operator: -\(rhs.type)")
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

func evalIfExpression(_ ifExp: IfExpression, _ env: Environment) -> Object {
  let condition = eval(ifExp.condition, env)
  if condition.isError {
    return condition
  } else if isTruthy(condition) {
    return eval(ifExp.consequence, env)
  } else if let alt = ifExp.alternative {
    return eval(alt, env)
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

func evalProgram(_ program: ProgramProtocol, _ env: Environment) -> Object {
  var result: Object = Error("program failed to evaluate")
  for statement in program.statements {
    result = eval(statement, env)
    if let returnValue = result as? ReturnValue {
      return returnValue.value
    } else if let _ = result as? Error {
      return result
    }
  }
  return result
}

func evalBlockStatement(_ block: BlockStatement, _ env: Environment) -> Object {
  var result: Object = Error("unexpected empty block statement")
  for statement in block.statements {
    result = eval(statement, env)
    switch result.type {
      case .returnValue, .error:
        return result
      default:
        break
    }
  }
  return result
}
