func testCode() {
  Test.reset(suiteName: "CodeTest")

  test("make") {
    let cases: [(OpCode, [Int], [UInt8])] = [
      (.constant, [65534], [OpCode.constant.asByte(), 255, 254]),
      (.add, [], [OpCode.add.asByte()]),
    ]

    cases.forEach { (opcode, operands, expectedBytes) in
      let instructions = make(opcode, operands)
      expect(instructions.count).toEqual(expectedBytes.count)
      instructions.enumerated().forEach { (index, instruction) in
        let expectedByte = expectedBytes[index]
        if instruction != expectedByte {
          Test.pushFail("wrong byte at pos \(index). want=\(expectedByte), got=\(instruction)")
        }
      }
    }
  }

  test("instructions string") {
    let instructions: [Instructions] = [
      make(.add, []),
      make(.constant, [2]),
      make(.constant, [65535]),
    ]

    let expected = """
      0000 OpAdd
      0001 OpConstant 2
      0004 OpConstant 65535

      """

    let concatted: Instructions = instructions.flatMap { $0 }
    expect(concatted.string).toEqual(expected)
  }

  test("read operands") {
    let cases: [(OpCode, [Int], Int)] = [
      (.constant, [65535], 2)
    ]
    cases.forEach { (opcode, operands, bytesRead) in
      let instruction = make(opcode, operands)
      let def = opcode.lookup()
      let (operandsRead, n) = readOperands(def, Array(instruction[1...]))
      guard expect(n).toEqual(bytesRead) else {
        return
      }
      guard expect(operandsRead.count).toEqual(operands.count) else {
        return
      }
      for (read, want) in zip(operandsRead, operands) {
        expect(read).toEqual(want)
      }
    }
  }

  Test.report()
}
