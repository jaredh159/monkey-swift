func testCode() {
  Test.reset(suiteName: "CodeTest")

  test("make") {
    let cases: [(OpCode, [Int], [UInt8])] = [
      (.constant, [65534], [OpCode.constant.asByte(), 255, 254])
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

  Test.report()
}
