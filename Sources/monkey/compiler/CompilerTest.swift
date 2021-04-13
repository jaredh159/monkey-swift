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
        input: "1 + 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.add),
          make(.pop),
        ]),
      CompilerTestCase(
        input: "1; 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.pop),
          make(.constant, [1]),
          make(.pop),
        ]),
      CompilerTestCase(
        input: "1 - 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.sub),
          make(.pop),
        ]),
      CompilerTestCase(
        input: "1 * 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.mul),
          make(.pop),
        ]),
      CompilerTestCase(
        input: "2 / 1",
        expectedConstants: [2, 1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.div),
          make(.pop),
        ]),
      CompilerTestCase(
        input: "-1",
        expectedConstants: [1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.minus),
          make(.pop),
        ]),
    ]
    runCompilerTests(tests)
  }

  test("boolean expressions") {
    let tests = [
      CompilerTestCase(
        input: "true",
        expectedConstants: [],
        expectedInstructions: [make(.true), make(.pop)]
      ),
      CompilerTestCase(
        input: "false",
        expectedConstants: [],
        expectedInstructions: [make(.false), make(.pop)]
      ),
      CompilerTestCase(
        input: "1 > 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.greaterThan),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "1 < 2",
        expectedConstants: [2, 1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.greaterThan),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "1 != 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.notEqual),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "1 == 2",
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.equal),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "true == false",
        expectedConstants: [],
        expectedInstructions: [
          make(.true),
          make(.false),
          make(.equal),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "true != false",
        expectedConstants: [],
        expectedInstructions: [
          make(.true),
          make(.false),
          make(.notEqual),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "!true",
        expectedConstants: [],
        expectedInstructions: [
          make(.true),
          make(.bang),
          make(.pop),
        ]
      ),
    ]
    runCompilerTests(tests)
  }

  test("conditionals") {
    runCompilerTests([
      CompilerTestCase(
        input: "if (true) { 10 }; 3333;",
        expectedConstants: [10, 3333],
        expectedInstructions: [
          // 0000
          make(.true),
          // 0001
          make(.jumpNotTruthy, [10]),
          // 0004
          make(.constant, [0]),
          // 0007
          make(.jump, [11]),
          // 0010
          make(.null),
          // 0011
          make(.pop),
          // 0012
          make(.constant, [1]),
          // 0015
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "if (true) { 10 } else { 20 }; 3333;",
        expectedConstants: [10, 20, 3333],
        expectedInstructions: [
          // 0000
          make(.true),
          // 0001
          make(.jumpNotTruthy, [10]),
          // 0004
          make(.constant, [0]),
          // 0007
          make(.jump, [13]),
          // 0010
          make(.constant, [1]),
          // 0013
          make(.pop),
          // 0014
          make(.constant, [2]),
          // 0017
          make(.pop),
        ]
      ),
    ])
  }

  test("global let statements") {
    runCompilerTests([
      CompilerTestCase(
        input: """
          let one = 1;
          let two = 2;
          """,
        expectedConstants: [1, 2],
        expectedInstructions: [
          make(.constant, [0]),
          make(.setGlobal, [0]),
          make(.constant, [1]),
          make(.setGlobal, [1]),
        ]
      ),
      CompilerTestCase(
        input: """
          let one = 1;
          one;
          """,
        expectedConstants: [1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          let one = 1;
          let two = one;
          two
          """,
        expectedConstants: [1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.setGlobal, [1]),
          make(.getGlobal, [1]),
          make(.pop),
        ]
      ),
    ])
  }

  test("string expressions") {
    runCompilerTests([
      CompilerTestCase(
        input: "\"monkey\"",
        expectedConstants: ["monkey"],
        expectedInstructions: [
          make(.constant, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "\"mon\" + \"key\"",
        expectedConstants: ["mon", "key"],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.add),
          make(.pop),
        ]
      ),
    ])
  }

  test("array literals") {
    runCompilerTests([
      CompilerTestCase(
        input: "[]",
        expectedConstants: [],
        expectedInstructions: [
          make(.array, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "[1, 2, 3]",
        expectedConstants: [1, 2, 3],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.constant, [2]),
          make(.array, [3]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "[1 + 2, 3 - 4, 5 * 6]",
        expectedConstants: [1, 2, 3, 4, 5, 6],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.add),
          make(.constant, [2]),
          make(.constant, [3]),
          make(.sub),
          make(.constant, [4]),
          make(.constant, [5]),
          make(.mul),
          make(.array, [3]),
          make(.pop),
        ]
      ),
    ])
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
    return
      "wrong instruction length.\n~~EXPECTED~~\n\(concatted.string)~~ACTUAL~~\n\(actual.string)"
  }
  var counter = 0
  for (expectedByte, actualByte) in zip(concatted, actual) {
    if expectedByte != actualByte {
      Test.pushFail(
        "wrong instruction at byte position \(counter) want=\(expectedByte), got=\(actualByte),\n~~~EXPECTED~~~\n\(concatted.string)~~~ACTUAL~~~\n\(actual.string)"
      )
    } else {
      Test.pushPass()
    }
    counter += 1
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
      case let string as String:
        expect(actual).toBeObject(string: string)
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
