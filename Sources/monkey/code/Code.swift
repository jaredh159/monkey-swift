typealias Instructions = [UInt8]

extension Array where Element == UInt8 {
  var string: String {
    var instructions: [String] = []
    var i = 0
    while i < self.count {
      guard let op = OpCode(rawValue: self[i]) else {
        instructions.append("ERROR: no opcode for value \(self[i])")
        continue
      }
      let def = op.lookup()
      let (operands, read) = readOperands(def, Array(self[(i + 1)...]))
      instructions.append("\(String(format: "%04d", i)) \(fmtInstructions(def, operands))")
      i += 1 + read
    }
    return "\(instructions.joined(separator: "\n"))\n"
  }
}

struct Definition {
  let name: String
  let operandWidths: [Int]
}

enum OpCode: UInt8 {
  case constant
  case add
  case pop
  case sub
  case mul
  case div
  case equal
  case notEqual
  case greaterThan
  case minus
  case bang
  case jumpNotTruthy
  case jump
  case null
  case setGlobal
  case getGlobal
  case setLocal
  case getLocal
  case getFree
  case getBuiltIn
  case array
  case hash
  case index
  case call
  case returnValue
  case closure
  case currentClosure
  case `return`
  case `true`
  case `false`

  func lookup() -> Definition {
    switch self {
      case .closure:
        return Definition(name: "closure", operandWidths: [2, 1])
      case .currentClosure:
        return Definition(name: "currentClosure", operandWidths: [])
      case .getFree:
        return Definition(name: "getFree", operandWidths: [1])
      case .getBuiltIn:
        return Definition(name: "getBuiltIn", operandWidths: [1])
      case .hash:
        return Definition(name: "hash", operandWidths: [2])
      case .array:
        return Definition(name: "array", operandWidths: [2])
      case .setGlobal:
        return Definition(name: "setGlobal", operandWidths: [2])
      case .getGlobal:
        return Definition(name: "getGlobal", operandWidths: [2])
      case .setLocal:
        return Definition(name: "setLocal", operandWidths: [1])
      case .getLocal:
        return Definition(name: "getLocal", operandWidths: [1])
      case .jumpNotTruthy:
        return Definition(name: "jumpNotTruthy", operandWidths: [2])
      case .jump:
        return Definition(name: "jump", operandWidths: [2])
      case .constant:
        return Definition(name: "constant", operandWidths: [2])
      case .call:
        return Definition(name: "call", operandWidths: [1])
      case .returnValue:
        return Definition(name: "returnValue", operandWidths: [])
      case .return:
        return Definition(name: "return", operandWidths: [])
      case .index:
        return Definition(name: "index", operandWidths: [])
      case .add:
        return Definition(name: "add", operandWidths: [])
      case .pop:
        return Definition(name: "pop", operandWidths: [])
      case .sub:
        return Definition(name: "sub", operandWidths: [])
      case .div:
        return Definition(name: "div", operandWidths: [])
      case .mul:
        return Definition(name: "mul", operandWidths: [])
      case .true:
        return Definition(name: "true", operandWidths: [])
      case .false:
        return Definition(name: "false", operandWidths: [])
      case .equal:
        return Definition(name: "equal", operandWidths: [])
      case .notEqual:
        return Definition(name: "notEqual", operandWidths: [])
      case .greaterThan:
        return Definition(name: "greaterThan", operandWidths: [])
      case .minus:
        return Definition(name: "minus", operandWidths: [])
      case .bang:
        return Definition(name: "bang", operandWidths: [])
      case .null:
        return Definition(name: "null", operandWidths: [])
    }
  }

  func asByte() -> UInt8 {
    return self.rawValue
  }
}

func make(_ opcode: OpCode, _ operands: [Int] = []) -> [UInt8] {
  let def = opcode.lookup()
  var instructionLen = 1
  for width in def.operandWidths {
    instructionLen += width
  }

  var instruction: [UInt8] = [opcode.asByte()]

  for (index, operand) in operands.enumerated() {
    let width = def.operandWidths[index]
    switch width {
      case 2:
        instruction.append(UInt8(truncatingIfNeeded: operand >> 8))
        instruction.append(UInt8(truncatingIfNeeded: operand))
      case 1:
        instruction.append(UInt8(operand))
      default:
        break
    }
  }
  return instruction
}

func readOperands(_ def: Definition, _ ins: Instructions) -> ([Int], Int) {
  var operands: [Int] = []
  var offset = 0
  for (_, width) in def.operandWidths.enumerated() {
    switch width {
      case 2:
        operands.append(Int(readUInt16(Array(ins[offset...]))))
      case 1:
        operands.append(Int(readUInt8(Array(ins[offset...]))))
      default:
        break
    }
    offset += width
  }
  return (operands, offset)
}

func readUInt16(_ ins: Instructions) -> UInt16 {
  return [ins[1], ins[0]].withUnsafeBytes { $0.load(as: UInt16.self) }
}

func readUInt8(_ ins: Instructions) -> UInt8 {
  return UInt8(ins[0])
}

func fmtInstructions(_ def: Definition, _ operands: [Int]) -> String {
  let operandCount = def.operandWidths.count
  guard operandCount == operands.count else {
    return "ERROR: operand len \(operands.count) does not match defined \(operandCount)\n"
  }
  let name = "Op\(def.name.prefix(1).capitalized)\(def.name.dropFirst())"
  switch operandCount {
    case 0:
      return name
    case 1:
      return "\(name) \(operands[0])"
    default:
      return "ERROR: unhandled operandCount for \(name)\n"
  }
}
