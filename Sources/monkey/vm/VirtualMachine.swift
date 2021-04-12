let GLOBALS_SIZE = 65536

class VirtualMachine {
  var constants: [Object]
  var instructions: Instructions
  var stack: [Object] = []
  var globals: [Object?]
  var sp: Int = 0
  private let STACK_SIZE = 2048

  var lastPoppedStackElem: Object? {
    return stack[sp]
  }

  init(_ bytecode: Bytecode) {
    self.constants = bytecode.constants
    self.instructions = bytecode.instructions
    self.globals = [Object?](repeating: nil, count: GLOBALS_SIZE)
  }

  init(_ bytecode: Bytecode, globals: [Object?]) {
    self.constants = bytecode.constants
    self.instructions = bytecode.instructions
    self.globals = globals
  }

  private func intFromUInt16Operand(_ ip: Int) -> Int {
    return Int(readUInt16(Array(instructions[(ip + 1)...])))
  }

  func run() -> VirtualMachineError? {
    var ip = 0
    while ip < instructions.count {
      guard let op = OpCode(rawValue: instructions[ip]) else {
        return .invalidOpCode(instructions[ip])
      }
      switch op {
        case .constant:
          let constIndex = intFromUInt16Operand(ip)
          ip += 2
          if let err = push(constants[constIndex]) {
            return err
          }
        case .add, .sub, .mul, .div:
          if let err = executeBinaryOperation(op) {
            return err
          }
        case .pop:
          pop()
        case .true, .false:
          if let err = push(op == .true ? Boolean.true : Boolean.false) {
            return err
          }
        case .equal, .notEqual, .greaterThan:
          if let err = executeComparison(op) {
            return err
          }
        case .bang:
          let operand = pop()
          switch operand {
            case Boolean.false:
              push(Boolean.true)
            case Null:
              push(Boolean.true)
            default:
              push(Boolean.false)
          }
        case .minus:
          if let err = executeMinusOperator() {
            return err
          }
        case .jump:
          let pos = intFromUInt16Operand(ip)
          ip = pos - 1
        case .jumpNotTruthy:
          let pos = intFromUInt16Operand(ip)
          ip += 2
          let condition = pop()
          if !isTruthy(condition) {
            ip = pos - 1
          }
        case .null:
          if let err = push(Null) {
            return err
          }
        case .setGlobal:
          let globalIndex = intFromUInt16Operand(ip)
          ip += 2
          globals[globalIndex] = pop()
        case .getGlobal:
          let globalIndex = intFromUInt16Operand(ip)
          ip += 2
          if let err = push(globals[globalIndex]!) {
            return err
          }
      }
      ip += 1
    }
    return nil
  }

  private func executeMinusOperator() -> VirtualMachineError? {
    let operand = pop()
    guard let int = operand as? Integer else {
      return .unexpectedObjectType
    }
    return push(Integer(value: -int.value))
  }

  private func executeComparison(_ op: OpCode) -> VirtualMachineError? {
    let right = pop()
    let left = pop()
    if let leftInt = left as? Integer, let rightInt = right as? Integer {
      return executeIntegerComparison(op, leftInt, rightInt)
    }
    if let leftBool = left as? Boolean, let rightBool = right as? Boolean {
      switch op {
        case .equal:
          return push(Boolean.from(leftBool === rightBool))
        case .notEqual:
          return push(Boolean.from(leftBool !== rightBool))
        default:
          return .unexpectedBooleanOperator(op.rawValue)
      }
    }
    return .unknownOperator(op.rawValue)
  }

  private func executeIntegerComparison(_ op: OpCode, _ left: Integer, _ right: Integer)
    -> VirtualMachineError?
  {
    switch op {
      case .equal:
        return push(Boolean.from(left.value == right.value))
      case .notEqual:
        return push(Boolean.from(left.value != right.value))
      case .greaterThan:
        return push(Boolean.from(left.value > right.value))
      default:
        return .unknownIntegerOperator(op.rawValue)
    }
  }

  private func executeBinaryOperation(_ op: OpCode) -> VirtualMachineError? {
    let right = pop()
    let left = pop()
    if let leftInt = left as? Integer, let rightInt = right as? Integer {
      return executeBinaryIntegerOperation(op, leftInt, rightInt)
    }
    if let leftStr = left as? StringObject, let rightStr = right as? StringObject {
      return executeBinaryStringOperation(op, leftStr, rightStr)
    }
    return .unexpectedObjectType
  }

  private func executeBinaryStringOperation(
    _ op: OpCode, _ left: StringObject, _ right: StringObject
  )
    -> VirtualMachineError?
  {
    guard op == .add else {
      return .unknownStringOperator(op.rawValue)
    }
    return push(StringObject(value: left.value + right.value))
  }

  private func executeBinaryIntegerOperation(_ op: OpCode, _ left: Integer, _ right: Integer)
    -> VirtualMachineError?
  {
    var result = 0
    switch op {
      case .add:
        result = left.value + right.value
      case .sub:
        result = left.value - right.value
      case .mul:
        result = left.value * right.value
      case .div:
        result = left.value / right.value
      default:
        return .unknownIntegerOperator(op.rawValue)
    }
    return push(Integer(value: result))
  }

  @discardableResult
  private func push(_ obj: Object) -> VirtualMachineError? {
    guard sp < STACK_SIZE else {
      return .stackOverflow
    }
    if sp == stack.count {
      stack.append(obj)
    } else {
      stack[sp] = obj
    }
    sp += 1
    return nil
  }

  @discardableResult
  private func pop() -> Object {
    let object = stack[sp - 1]
    sp -= 1
    return object
  }

  private func isTruthy(_ object: Object) -> Bool {
    switch object {
      case let bool as Boolean:
        return bool.value
      case Null:
        return false
      default:
        return true
    }
  }
}

enum VirtualMachineError: Swift.Error {
  case stackOverflow
  case invalidOpCode(UInt8)
  case unknownOperator(UInt8)
  case unknownIntegerOperator(UInt8)
  case unexpectedObjectType
  case unexpectedBooleanOperator(UInt8)
  case unknownStringOperator(UInt8)
  case unknown
}
