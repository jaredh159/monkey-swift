typealias Instructions = [UInt8]
// typealias Opcode = UInt8

enum OpCode: UInt8 {
  case constant = 0

  struct Definition {
    let name: String
    let operandWidths: [Int]
  }

  func lookup() -> Definition {
    switch self {
      case .constant:
        return Definition(name: "constant", operandWidths: [2])
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
