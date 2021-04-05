class VirtualMachine {
  var constants: [Object]
  var instructions: Instructions
  var stack: [Object] = []
  var sp: Int = 0
  private let STACK_SIZE = 2048

  var lastPoppedStackElem: Object? {
    return stack[sp]
  }

  init(_ bytecode: Bytecode) {
    self.constants = bytecode.constants
    self.instructions = bytecode.instructions
  }

  func run() -> VirtualMachineError? {
    var ip = 0
    while ip < instructions.count {
      guard let op = OpCode(rawValue: instructions[ip]) else {
        return .invalidOpCode(instructions[ip])
      }
      switch op {
        case .constant:
          let constIndex = Int(readUInt16(Array(instructions[(ip + 1)...])))
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
        case .true:
          if let err = push(Boolean.true) {
            return err
          }
        case .false:
          if let err = push(Boolean.false) {
            return err
          }
      }
      ip += 1
    }
    return nil
  }

  private func executeBinaryOperation(_ op: OpCode) -> VirtualMachineError? {
    let right = pop()
    let left = pop()
    if let leftInt = left as? Integer, let rightInt = right as? Integer {
      return executeBinaryIntegerOperation(op, leftInt, rightInt)
    }
    return .unexpectedObjectType
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
  func push(_ obj: Object) -> VirtualMachineError? {
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
  func pop() -> Object {
    let object = stack[sp - 1]
    sp -= 1
    return object
  }
}

enum VirtualMachineError: Swift.Error {
  case stackOverflow
  case invalidOpCode(UInt8)
  case unknownIntegerOperator(UInt8)
  case unexpectedObjectType
  case unknown
}
