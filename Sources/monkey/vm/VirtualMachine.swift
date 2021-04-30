let GLOBALS_SIZE = 65536

class VirtualMachine {
  private var constants: [Object]
  private var stack: [Object?]
  private var globals: [Object?]
  private var sp = 0
  private var frames: [Frame?]
  private var frameIndex = 1
  private let STACK_SIZE = 2048
  private let MAX_FRAMES = 1024

  private var currentFrame: Frame { frames[frameIndex - 1]! }

  var lastPoppedStackElem: Object? { return stack[sp] }

  private var ip: Int {
    get { currentFrame.ip }
    set { currentFrame.ip = newValue }
  }

  private var instructions: Instructions { currentFrame.instructions }

  convenience init(_ bytecode: Bytecode) {
    let globals = [Object?](repeating: nil, count: GLOBALS_SIZE)
    self.init(bytecode, globals: globals)
  }

  init(_ bytecode: Bytecode, globals: [Object?]) {
    self.constants = bytecode.constants
    self.globals = globals
    self.frames = [Frame?](repeating: nil, count: MAX_FRAMES)
    self.stack = [Object?](repeating: nil, count: STACK_SIZE)

    let mainFn = CompiledFunction(
      instructions: bytecode.instructions,
      numLocals: 0,
      numParameters: 0
    )
    let mainClosure = Closure(fn: mainFn, free: [])

    let mainFrame = Frame(closure: mainClosure, basePointer: 0)
    self.frames[0] = mainFrame
  }

  func run() -> VirtualMachineError? {
    while ip < instructions.count - 1 {
      ip += 1
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

        case .array:
          let numElements = intFromUInt16Operand(ip)
          ip += 2
          let array = buildArray(startIndex: sp - numElements, endIndex: sp)
          sp = sp - numElements
          if let err = push(array) {
            return err
          }

        case .hash:
          let numElements = intFromUInt16Operand(ip)
          ip += 2
          let (hash, err) = buildHash(startIndex: sp - numElements, endIndex: sp)
          if let err = err {
            return err
          }
          sp = sp - numElements
          if let err = push(hash!) {
            return err
          }

        case .index:
          let index = pop()
          let left = pop()
          if let err = executeIndexExpression(left: left, index: index) {
            return err
          }

        case .return:
          let frame = popFrame()
          sp = frame.basePointer - 1
          if let err = push(Null) {
            return err
          }

        case .returnValue:
          let returnValue = pop()
          let frame = popFrame()
          sp = frame.basePointer - 1
          if let err = push(returnValue) {
            return err
          }

        case .call:
          let numArgs = intFromUInt8Operand(ip)
          ip += 1
          if let err = executeCall(numArgs) {
            return err
          }

        case .setLocal:
          let localIndex = intFromUInt8Operand(ip)
          ip += 1
          stack[currentFrame.basePointer + localIndex] = pop()

        case .getLocal:
          let localIndex = intFromUInt8Operand(ip)
          ip += 1
          if let err = push(stack[currentFrame.basePointer + localIndex]!) {
            return err
          }

        case .getBuiltIn:
          let builtInIndex = intFromUInt8Operand(ip)
          ip += 1
          guard let builtIn = BuiltIns(from: builtInIndex) else {
            return .invalidBuiltInFnIndex(builtInIndex)
          }
          if let err = push(builtIn.object()) {
            return err
          }

        case .closure:
          let constIndex = intFromUInt16Operand(ip)
          _ = intFromUInt8Operand(ip + 2)  // I think +2 is correct
          ip += 3
          if let err = pushClosure(constIndex) {
            return err
          }

        case .getFree:
          fatalError("not implemented: .getFree")
      }
    }
    return nil
  }

  private func executeCall(_ numArgs: Int) -> VirtualMachineError? {
    let callee = stack[sp - numArgs - 1]
    switch callee {
      case let closure as Closure:
        return callClosure(closure, numArgs)
      case let builtIn as BuiltIn:
        return callBuiltIn(builtIn, numArgs)
      default:
        return .nonCallableCall
    }
  }

  private func callBuiltIn(_ builtIn: BuiltIn, _ numArgs: Int) -> VirtualMachineError? {
    let args = stack[sp - numArgs..<sp].compactMap { $0 }
    let result = builtIn.fn(args)
    sp = sp - numArgs - 1
    return push(result)
  }

  private func callClosure(_ closure: Closure, _ numArgs: Int) -> VirtualMachineError? {
    guard numArgs == closure.fn.numParameters else {
      return .fnArity(closure.fn.numParameters, numArgs)
    }
    let frame = Frame(closure: closure, basePointer: sp - numArgs)
    pushFrame(frame)
    sp = frame.basePointer + closure.fn.numLocals
    return nil
  }

  private func pushClosure(_ constIndex: Int) -> VirtualMachineError? {
    let constant = constants[constIndex]
    guard let fn = constant as? CompiledFunction else {
      return .unexpectedObjectType
    }
    return push(Closure(fn: fn, free: []))
  }

  private func pushFrame(_ frame: Frame) {
    frames[frameIndex] = frame
    frameIndex += 1
  }

  @discardableResult
  private func popFrame() -> Frame {
    frameIndex -= 1
    guard let frame = frames[frameIndex] else {
      fatalError("nil frame found at index \(frameIndex)")
    }
    return frame
  }

  private func executeIndexExpression(left: Object, index: Object) -> VirtualMachineError? {
    switch (left, index) {
      case let (array as ArrayObject, int as Integer):
        return executeArrayIndex(array, int)
      case let (hash as Hash, _):
        return executeHashIndex(hash, index)
      default:
        return .indexOperatorUnsupported(left.type.description)
    }
  }

  private func executeArrayIndex(_ array: ArrayObject, _ int: Integer) -> VirtualMachineError? {
    guard array.elements.indices.contains(int.value) else {
      return push(Null)
    }
    return push(array.elements[int.value])
  }

  private func executeHashIndex(_ hash: Hash, _ index: Object) -> VirtualMachineError? {
    guard let hashKey = HashKey(index) else {
      return .unusableHashKey(index.type.description)
    }
    guard let pair = hash.pairs[hashKey] else {
      return push(Null)
    }
    return push(pair.value)
  }

  private func buildHash(startIndex: Int, endIndex: Int) -> (Hash?, VirtualMachineError?) {
    var pairs: [HashKey: HashPair] = [:]
    for i in stride(from: startIndex, to: endIndex, by: 2) {
      let key = stack[i]!
      let value = stack[i + 1]!
      guard let hashKey = HashKey(key) else {
        return (nil, .unusableHashKey(key.type.description))
      }
      pairs[hashKey] = HashPair(key: key, value: value)
    }
    return (Hash(pairs: pairs), nil)
  }

  private func buildArray(startIndex: Int, endIndex: Int) -> ArrayObject {
    var elements: [Object] = []
    for i in startIndex..<endIndex {
      elements.append(stack[i]!)
    }
    return ArrayObject(elements: elements)
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
    switch (left, right, op) {
      case let (leftInt as Integer, rightInt as Integer, _):
        return executeIntegerComparison(op, leftInt, rightInt)
      case let (leftBool as Boolean, rightBool as Boolean, .equal):
        return push(Boolean.from(leftBool === rightBool))
      case let (leftBool as Boolean, rightBool as Boolean, .notEqual):
        return push(Boolean.from(leftBool !== rightBool))
      case (_ as Boolean, _ as Boolean, _):
        return .unexpectedBooleanOperator(op.rawValue)
      default:
        return .unknownOperator(op.rawValue)
    }
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
    switch (left, right) {
      case let (leftInt as Integer, rightInt as Integer):
        return executeBinaryIntegerOperation(op, leftInt, rightInt)
      case let (leftStr as StringObject, rightStr as StringObject):
        return executeBinaryStringOperation(op, leftStr, rightStr)
      default:
        return .unexpectedObjectType
    }
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
    stack[sp] = obj
    sp += 1
    return nil
  }

  @discardableResult
  private func pop() -> Object {
    let object = stack[sp - 1]!
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

  private func intFromUInt16Operand(_ ip: Int) -> Int {
    return Int(readUInt16(Array(currentFrame.instructions[(ip + 1)...])))
  }

  private func intFromUInt8Operand(_ ip: Int) -> Int {
    return Int(readUInt8(Array(currentFrame.instructions[(ip + 1)...])))
  }
}

enum VirtualMachineError: Swift.Error, CustomStringConvertible {
  case stackOverflow
  case invalidOpCode(UInt8)
  case unknownOperator(UInt8)
  case unknownIntegerOperator(UInt8)
  case unexpectedObjectType
  case unexpectedBooleanOperator(UInt8)
  case unknownStringOperator(UInt8)
  case unusableHashKey(String)
  case indexOperatorUnsupported(String)
  case fnArity(Int, Int)
  case invalidBuiltInFnIndex(Int)
  case nonCallableCall
  case unknown

  var description: String {
    switch self {
      case .stackOverflow:
        return "stack overflow"
      case .invalidOpCode(let int):
        return "invalid opcode: \(int)"
      case .unknownOperator(let int):
        return "unknown operator: \(int)"
      case .unknownIntegerOperator(let int):
        return "unknown integer operator: \(int)"
      case .unexpectedObjectType:
        return "unexpected object type"
      case .unexpectedBooleanOperator(let int):
        return "unknown boolen operator: \(int)"
      case .unknownStringOperator(let int):
        return "unknown string operator: \(int)"
      case .unusableHashKey(let string):
        return "unusable hash key: \(string)"
      case .indexOperatorUnsupported(let op):
        return "index operator unsupported: \(op)"
      case .fnArity(let expected, let actual):
        return "wrong number of arguments: want=\(expected), got=\(actual)"
      case .invalidBuiltInFnIndex(let int):
        return "invalid built-in fn index: \(int)"
      case .nonCallableCall:
        return "non callable (closure or builtIn) call"
      case .unknown:
        return "unknown error"
    }
  }
}
