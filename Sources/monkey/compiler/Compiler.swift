struct Bytecode {
  var instructions: Instructions
  var constants: [Object]
}

enum CompilerError: Swift.Error {
  case unknown
  case unknownInfixOperator(String)
  case unknownPrefixOperator(String)
}

class Compiler {
  var instructions: Instructions = []
  var constants: [Object] = []

  func compile(_ node: Node) -> CompilerError? {
    switch node {
      case let program as ProgramProtocol:
        for statement in program.statements {
          if let err = compile(statement) {
            return err
          }
        }
      case let exprStmt as ExpressionStatement:
        if let err = compile(exprStmt.expression) {
          return err
        }
        emit(opcode: .pop, operands: [])
      case let infixExpr as InfixExpression:
        if infixExpr.operator == "<" {
          if let err = compile(infixExpr.right) {
            return err
          }
          if let err = compile(infixExpr.left) {
            return err
          }
          emit(opcode: .greaterThan)
          return nil
        }
        if let err = compile(infixExpr.left) {
          return err
        }
        if let err = compile(infixExpr.right) {
          return err
        }
        switch infixExpr.operator {
          case "-":
            emit(opcode: .sub)
          case "*":
            emit(opcode: .mul)
          case "/":
            emit(opcode: .div)
          case "+":
            emit(opcode: .add)
          case ">":
            emit(opcode: .greaterThan)
          case "==":
            emit(opcode: .equal)
          case "!=":
            emit(opcode: .notEqual)
          default:
            return .unknownInfixOperator(infixExpr.operator)
        }
      case let intLit as IntegerLiteral:
        let integer = Integer(value: intLit.value)
        emit(opcode: .constant, operands: [addConstant(integer)])
      case let bool as BooleanLiteral:
        emit(opcode: bool.value ? .true : .false)
      case let prefixExpr as PrefixExpression:
        if let err = compile(prefixExpr.right) {
          return err
        }
        switch prefixExpr.operator {
          case "!":
            emit(opcode: .bang)
          case "-":
            emit(opcode: .minus)
          default:
            return .unknownPrefixOperator(prefixExpr.operator)
        }
      default:
        fatalError("Unhandled node type: \(type(of: node))")
    }
    return nil
  }

  @discardableResult
  private func emit(opcode: OpCode, operands: [Int] = []) -> Int {
    let ins = make(opcode, operands)
    return addInstruction(ins)
  }

  private func addInstruction(_ ins: [UInt8]) -> Int {
    let posNewInstruction = instructions.count
    instructions += ins
    return posNewInstruction
  }

  private func addConstant(_ obj: Object) -> Int {
    constants.append(obj)
    return constants.count - 1
  }

  func bytecode() -> Bytecode {
    return Bytecode(instructions: instructions, constants: constants)
  }
}
