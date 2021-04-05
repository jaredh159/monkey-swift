typealias Instructions = [UInt8]
// typealias Opcode = UInt8

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
    return "[\(instructions.joined(separator: ", "))]"
  }
}

struct Definition {
  let name: String
  let operandWidths: [Int]
}

enum OpCode: UInt8 {
  case constant
  case add

  func lookup() -> Definition {
    switch self {
      case .constant:
        return Definition(name: "constant", operandWidths: [2])
      case .add:
        return Definition(name: "add", operandWidths: [])
    }
  }

  func asByte() -> UInt8 {
    return self.rawValue
  }
}

func make(_ opcode: OpCode, _ operands: [Int]) -> [UInt8] {
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
        break
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

func fmtInstructions(_ def: Definition, _ operands: [Int]) -> String {
  let operandCount = def.operandWidths.count
  guard operandCount == operands.count else {
    return "ERROR: operand len \(operands.count) does not match defined \(operandCount)\n"
  }
  switch operandCount {
    case 0:
      return "Op\(def.name.capitalized)"
    case 1:
      return "Op\(def.name.capitalized) \(operands[0])"
    default:
      return "ERROR: unhandled operandCount for \(def.name)\n"
  }
}
