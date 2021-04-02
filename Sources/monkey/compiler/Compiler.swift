struct Bytecode {
  var instructions: Instructions
  var constants: [Object]
}

enum CompilerError: Swift.Error {
  case unknown
}

struct Compiler {
  var instructions: Instructions = []
  var constants: [Object] = []

  mutating func compile(_ node: Node) -> CompilerError? {
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
      case let infixExpr as InfixExpression:
        if let err = compile(infixExpr.left) {
          return err
        }
        if let err = compile(infixExpr.right) {
          return err
        }
      case let intLit as IntegerLiteral:
        let integer = Integer(value: intLit.value)
        emit(opcode: .constant, operands: [addConstant(integer)])
      default:
        fatalError("whoops...")
    }
    return nil
  }

  @discardableResult
  private mutating func emit(opcode: OpCode, operands: [Int]) -> Int {
    let ins = make(opcode, operands)
    return addInstruction(ins)
  }

  private mutating func addInstruction(_ ins: [UInt8]) -> Int {
    let posNewInstruction = instructions.count
    instructions += ins
    return posNewInstruction
  }

  private mutating func addConstant(_ obj: Object) -> Int {
    constants.append(obj)
    return constants.count - 1
  }

  func bytecode() -> Bytecode {
    return Bytecode(instructions: instructions, constants: constants)
  }
}
