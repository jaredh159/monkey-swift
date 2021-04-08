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
  private var instructions: Instructions = []
  private var constants: [Object] = []
  private var lastInstruction: EmittedInstruction?
  private var previousInstruction: EmittedInstruction?

  struct EmittedInstruction {
    var opcode: OpCode
    var position: Int
  }

  func bytecode() -> Bytecode {
    return Bytecode(instructions: instructions, constants: constants)
  }

  func compile(_ node: Node) -> CompilerError? {
    switch node {

      case let program as ProgramProtocol:
        for statement in program.statements {
          if let err = compile(statement) {
            return err
          }
        }

      case let blockStatement as BlockStatement:
        for statement in blockStatement.statements {
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

      case let ifExpr as IfExpression:
        if let err = compile(ifExpr.condition) {
          return err
        }
        let jumpNotTruthyPos = emit(opcode: .jumpNotTruthy, operands: [PLACEHOLDER])
        if let err = compile(ifExpr.consequence) {
          return err
        }
        if lastInstruction?.opcode == .pop {
          removeLastPop()
        }

        if let alternative = ifExpr.alternative {
          let jumpPos = emit(opcode: .jump, operands: [PLACEHOLDER])
          let afterConsequencePos = instructions.count
          changeOperand(atOpCodePosition: jumpNotTruthyPos, with: afterConsequencePos)
          if let err = compile(alternative) {
            return err
          }
          if lastInstruction?.opcode == .pop {
            removeLastPop()
          }
          let afterAlternativePos = instructions.count
          changeOperand(atOpCodePosition: jumpPos, with: afterAlternativePos)
        } else {
          let afterConsequencePos = instructions.count
          changeOperand(atOpCodePosition: jumpNotTruthyPos, with: afterConsequencePos)
        }

      default:
        fatalError("Unhandled node type: \(type(of: node))")
    }
    return nil
  }

  @discardableResult
  private func emit(opcode: OpCode, operands: [Int] = []) -> Int {
    let ins = make(opcode, operands)
    let pos = addInstruction(ins)
    setLastInstruction(opcode, pos)
    return pos
  }

  private func setLastInstruction(_ opcode: OpCode, _ pos: Int) {
    previousInstruction = lastInstruction
    lastInstruction = EmittedInstruction(opcode: opcode, position: pos)
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

  private func removeLastPop() {
    instructions = instructions.dropLast()
    lastInstruction = previousInstruction
  }

  private func replaceInstruction(atPosition pos: Int, with newInstruction: Instructions) {
    for i in 0..<newInstruction.count {
      instructions[pos + i] = newInstruction[i]
    }
  }

  private func changeOperand(atOpCodePosition opPos: Int, with newOperand: Int) {
    guard let op = OpCode(rawValue: instructions[opPos]) else {
      fatalError("byte at position \(opPos) is not a valid opcode")
    }
    let newInstruction = make(op, [newOperand])
    replaceInstruction(atPosition: opPos, with: newInstruction)
  }
}

private var PLACEHOLDER = 255
