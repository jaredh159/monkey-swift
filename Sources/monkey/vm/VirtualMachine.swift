class VirtualMachine {
  var constants: [Object]
  var instructions: Instructions
  var stack: [Object] = []
  var sp: Int = 0
  private let STACK_SIZE = 2048

  var stackTop: Object? {
    return stack.last
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
      }
      ip += 1
    }
    return nil
  }

  func push(_ obj: Object) -> VirtualMachineError? {
    guard sp < STACK_SIZE else {
      return .stackOverflow
    }
    stack.append(obj)
    sp += 1
    return nil
  }
}

enum VirtualMachineError: Swift.Error {
  case stackOverflow
  case invalidOpCode(UInt8)
  case unknown
}
