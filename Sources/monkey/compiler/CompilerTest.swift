struct CompilerTestCase {
  var input: String
  var expectedConstants: [Any]
  var expectedInstructions: [Instructions]
}

func testCompiler() {
  Test.reset(suiteName: "CompilerTest")

  test("integer arithmetic") {
    let tests = [
      CompilerTestCase(
        input: "1 + 2", expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.add, []),
        ])
    ]
    runCompilerTests(tests)
  }

  Test.report()
}

func runCompilerTests(_ tests: [CompilerTestCase]) {
  for test in tests {
    let program = parse(test.input)
    let compiler = Compiler()
    if let err = compiler.compile(program) {
      Test.pushFail("compiler error: \(err)")
      return
    }

    let bytecode = compiler.bytecode()
    if let err = testInstructions(test.expectedInstructions, bytecode.instructions) {
      Test.pushFail("testInstructions failed: \(err)")
    }

    if let err = testConstants(test.expectedConstants, bytecode.constants) {
      Test.pushFail("testConstants failed: \(err)")
    }
  }
}

func parse(_ input: String) -> ProgramProtocol {
  let lexer = Lexer(input)
  let parser = Parser(lexer)
  return parser.parseProgram()
}

func testInstructions(_ expected: [Instructions], _ actual: Instructions) -> String? {
  let concatted = concatInstructions(expected)
  guard concatted.count == actual.count else {
    return "wrong instruction length. want=\(concatted.string), got=\(actual.string)"
  }
  for (expectedByte, actualByte) in zip(concatted, actual) {
    expect(expectedByte).toEqual(actualByte)
  }
  return nil
}

func testConstants(_ expectedConstants: [Any], _ actualConstants: [Object]) -> String? {
  if expectedConstants.count != actualConstants.count {
    return
      "wrong number of constants, got=\(actualConstants.count), want=\(expectedConstants.count)"
  }
  for (expected, actual) in zip(expectedConstants, actualConstants) {
    switch expected {
      case let int as Int:
        expect(actual).toBeObject(int: int)
      default:
        return "unexpected expected type \(type(of: expected))"
    }
  }
  return nil
}

func concatInstructions(_ instructions: [Instructions]) -> Instructions {
  var out: Instructions = []
  for instruction in instructions {
    out += instruction
  }
  return out
}
