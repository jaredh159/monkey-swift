struct Bytecode {
  var instructions: Instructions
  var constants: [Object]
}

enum CompilerError: Swift.Error {
  case unknown
  case unknownInfixOperator(String)
  case unknownPrefixOperator(String)
  case undefinedVariable(String)
}

class Compiler {
  private(set) var symbolTable: SymbolTable
  private var constants: [Object]
  private(set) var scopes: [Scope] = [Scope()]
  private(set) var scopeIndex = 0

  var currentScope: Scope {
    guard scopes.indices.contains(scopeIndex) else {
      fatalError("FATAL ERROR: No scope at index \(scopeIndex)")
    }
    return scopes[scopeIndex]
  }

  private(set) var instructions: Instructions {
    get { currentScope.instructions }
    set { scopes[scopeIndex].instructions = newValue }
  }

  private(set) var lastInstruction: EmittedInstruction {
    get { currentScope.lastInstruction }
    set { scopes[scopeIndex].lastInstruction = newValue }
  }

  private(set) var previousInstruction: EmittedInstruction {
    get { currentScope.previousInstruction }
    set { scopes[scopeIndex].previousInstruction = newValue }
  }

  struct Scope {
    var instructions: Instructions = []
    var lastInstruction = EmittedInstruction(opcode: .null, position: -1)
    var previousInstruction = EmittedInstruction(opcode: .null, position: -2)
  }

  struct EmittedInstruction {
    var opcode: OpCode
    var position: Int
  }

  convenience init() {
    self.init(symbolTable: SymbolTable(), constants: [])
  }

  init(symbolTable: SymbolTable, constants: [Object]) {
    for (index, builtIn) in BuiltIns.allCases.enumerated() {
      symbolTable.defineBuiltIn(name: builtIn.rawValue, index: index)
    }
    self.symbolTable = symbolTable
    self.constants = constants
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

      case let letStmt as LetStatement:
        let symbol = symbolTable.define(name: letStmt.name.value)
        if let err = compile(letStmt.value) {
          return err
        }
        let opcode: OpCode = symbol.scope == .global ? .setGlobal : .setLocal
        emit(opcode: opcode, operands: [symbol.index])

      case let ifExpr as IfExpression:
        if let err = compile(ifExpr.condition) {
          return err
        }

        let jumpNotTruthyPos = emit(opcode: .jumpNotTruthy, operands: [PLACEHOLDER])
        if let err = compile(ifExpr.consequence) {
          return err
        }

        if lastInstruction.opcode == .pop {
          removeLastPop()
        }

        let jumpPos = emit(opcode: .jump, operands: [PLACEHOLDER])
        let afterConsequencePos = instructions.count
        changeOperand(atOpCodePosition: jumpNotTruthyPos, with: afterConsequencePos)

        if let alternative = ifExpr.alternative {
          if let err = compile(alternative) {
            return err
          }
          if lastInstruction.opcode == .pop {
            removeLastPop()
          }
        } else {
          emit(opcode: .null)
        }

        let afterAlternativePos = instructions.count
        changeOperand(atOpCodePosition: jumpPos, with: afterAlternativePos)

      case let identifier as Identifier:
        guard let symbol = symbolTable.resolve(name: identifier.value) else {
          return .undefinedVariable(identifier.value)
        }
        loadSymbol(symbol)

      case let stringLit as StringLiteral:
        let strObj = StringObject(value: stringLit.value)
        emit(opcode: .constant, operands: [addConstant(strObj)])

      case let arrayLit as ArrayLiteral:
        for element in arrayLit.elements {
          if let err = compile(element) {
            return err
          }
        }
        emit(opcode: .array, operands: [arrayLit.elements.count])

      case let hashLit as HashLiteral:
        for (key, value) in hashLit.pairs {
          if let err = compile(key) {
            return err
          }
          if let err = compile(value) {
            return err
          }
        }
        emit(opcode: .hash, operands: [hashLit.pairs.count * 2])

      case let indexExpr as IndexExpression:
        if let err = compile(indexExpr.left) {
          return err
        }
        if let err = compile(indexExpr.index) {
          return err
        }
        emit(opcode: .index)

      case let fnLit as FunctionLiteral:
        enterScope()
        if let name = fnLit.name {
          symbolTable.defineFunction(name: name)
        }
        for param in fnLit.parameters {
          symbolTable.define(name: param.value)
        }
        if let err = compile(fnLit.body) {
          return err
        }
        if lastInstruction.opcode == .pop {
          replaceLastPopWithReturn()
        }
        if lastInstruction.opcode != .returnValue {
          emit(opcode: .return)
        }
        let freeSymbols = symbolTable.freeSymbols
        let numLocals = symbolTable.numDefinitions
        let instructions = leaveScope()
        for free in freeSymbols {
          loadSymbol(free)
        }
        let compiledFn = CompiledFunction(
          instructions: instructions,
          numLocals: numLocals,
          numParameters: fnLit.parameters.count
        )
        let fnIndex = addConstant(compiledFn)
        emit(opcode: .closure, operands: [fnIndex, freeSymbols.count])

      case let returnStmt as ReturnStatement:
        if let err = compile(returnStmt.returnValue) {
          return err
        }
        emit(opcode: .returnValue)

      case let callExp as CallExpression:
        if let err = compile(callExp.function) {
          return err
        }
        for argument in callExp.arguments {
          if let err = compile(argument) {
            return err
          }
        }
        emit(opcode: .call, operands: [callExp.arguments.count])

      default:
        fatalError("Unhandled node type: \(type(of: node))")
    }
    return nil
  }

  @discardableResult
  func emit(opcode: OpCode, operands: [Int] = []) -> Int {
    let ins = make(opcode, operands)
    let pos = addInstruction(ins)
    setLastInstruction(opcode, pos)
    return pos
  }

  func enterScope() {
    scopes.append(Scope())
    symbolTable = SymbolTable(enclosedBy: symbolTable)
    scopeIndex += 1
  }

  func leaveScope() -> Instructions {
    let scopeInstructions = instructions
    scopes.removeLast()
    scopeIndex -= 1
    symbolTable = symbolTable.outer!
    return scopeInstructions
  }

  private func replaceLastPopWithReturn() {
    let lastPos = lastInstruction.position
    replaceInstruction(atPosition: lastPos, with: make(.returnValue))
    lastInstruction.opcode = .returnValue
  }

  private func setLastInstruction(_ opcode: OpCode, _ pos: Int) {
    previousInstruction = lastInstruction
    lastInstruction = EmittedInstruction(opcode: opcode, position: pos)
  }

  private func addInstruction(_ ins: [UInt8]) -> Int {
    let posNewInstruction = instructions.count
    scopes[scopeIndex].instructions += ins
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

  private func loadSymbol(_ symbol: Symbol) {
    switch symbol.scope {
      case .local:
        emit(opcode: .getLocal, operands: [symbol.index])
      case .global:
        emit(opcode: .getGlobal, operands: [symbol.index])
      case .builtIn:
        emit(opcode: .getBuiltIn, operands: [symbol.index])
      case .free:
        emit(opcode: .getFree, operands: [symbol.index])
      case .function:
        emit(opcode: .currentClosure)
    }
  }
}

private var PLACEHOLDER = 255
