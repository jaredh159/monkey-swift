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
    case let arrayLit as ArrayLiteral:
      let elements = evalExpressions(arrayLit.elements, env)
      if elements.count == 1 && elements.first.isError {
        return elements.first!
      }
      return ArrayObject(elements: elements)
    case let indexExpr as IndexExpression:
      let left = eval(indexExpr.left, env)
      if left.isError {
        return left
      }
      let index = eval(indexExpr.index, env)
      if index.isError {
        return index
      }
      return evalIndexExpression(left, index)
    case let hashLiteral as HashLiteral:
      return evalHashLiteral(hashLiteral, env)
    default:
      return Error("unexpected node type \(node?.string ?? "nil")")
  }
}

func evalHashLiteral(_ hashLit: HashLiteral, _ env: Environment) -> Object {
  var pairs: [HashKey: HashPair] = [:]
  for (keyNode, valueNode) in hashLit.pairs {
    let key = eval(keyNode, env)
    guard !key.isError else {
      return key
    }
    guard let hashKey = HashKey(key) else {
      return Error("unusable as hash key: \(key.type)")
    }
    let value = eval(valueNode, env)
    guard !value.isError else {
      return value
    }
    pairs[hashKey] = HashPair(key: key, value: value)
  }
  return Hash(pairs: pairs)
}

func evalIndexExpression(_ left: Object, _ index: Object) -> Object {
  if let array = left as? ArrayObject, let int = index as? Integer {
    return evalArrayIndexExpression(array, int.value)
  }
  if let hash = left as? Hash {
    return evalHashIndexExpression(hash, index)
  }
  return Error("index operator not supported: \(left.type)")
}

func evalHashIndexExpression(_ hash: Hash, _ index: Object) -> Object {
  guard let hashKey = HashKey(index) else {
    return Error("unusable as hash key: \(index.type)")
  }
  guard let pair = hash.pairs[hashKey] else {
    return Null
  }
  return pair.value
}

func evalArrayIndexExpression(_ array: ArrayObject, _ index: Int) -> Object {
  let max = array.elements.count - 1
  guard index >= 0 && index <= max else {
    return Null
  }
  return array.elements[index]
}

func applyFunction(_ obj: Object, _ args: [Object]) -> Object {
  switch obj {
    case let fn as Function:
      let extendedEnv = extendFunctionEnv(fn, args)
      let evaluated = eval(fn.body, extendedEnv)
      return unwrapReturnValue(evaluated)
    case let builtin as BuiltIn:
      return builtin.fn(args)
    default:
      return Error("not a function: \(obj.type)")
  }
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
  if let value = env.get(ident.value) {
    return value
  }

  if let builtin = MonkeyBuiltins[ident.value] {
    return builtin
  }

  return Error("identifier not found: \(ident.value)")
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

func evalInfixExpression(operator op: String, lhs: Object?, rhs: Object?) -> Object {
  guard let lhs = lhs, let rhs = rhs else {
    return Error("missing one side of infix expression")
  }
  switch (lhs, rhs, op) {
    case let (leftInt as Integer, rightInt as Integer, _):
      return evalIntegerInfixExpression(op: op, lhs: leftInt, rhs: rightInt)
    case let (leftBool as Boolean, rightBool as Boolean, "!="):
      return Boolean.from(leftBool !== rightBool)
    case let (leftBool as Boolean, rightBool as Boolean, "=="):
      return Boolean.from(leftBool === rightBool)
    case (_ as Boolean, _ as Boolean, _):
      return Error("unknown boolean operator: \(op)")
    case let (leftStr as StringObject, rightStr as StringObject, "+"):
      return StringObject(value: leftStr.value + rightStr.value)
    case (_ as StringObject, _ as StringObject, _):
      return Error("unknown string operator: \(op)")
    default:
      return Error("type mismatch: \(lhs.type) \(op) \(rhs.type)")
  }
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
