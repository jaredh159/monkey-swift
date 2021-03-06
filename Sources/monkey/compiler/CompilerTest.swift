struct CompilerTestCase {
  var input: String
  var expectedConstants: [Any]
  var expectedInstructions: [Instructions]
}

func testCompiler() -> Bool {
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

  test("hash literals") {
    runCompilerTests([
      CompilerTestCase(
        input: "{}",
        expectedConstants: [],
        expectedInstructions: [
          make(.hash, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "{1: 2, 3: 4, 5: 6}",
        expectedConstants: [1, 2, 3, 4, 5, 6],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.constant, [2]),
          make(.constant, [3]),
          make(.constant, [4]),
          make(.constant, [5]),
          make(.hash, [6]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "{1: 2 + 3, 4: 5 * 6}",
        expectedConstants: [1, 2, 3, 4, 5, 6],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.constant, [2]),
          make(.add),
          make(.constant, [3]),
          make(.constant, [4]),
          make(.constant, [5]),
          make(.mul),
          make(.hash, [4]),
          make(.pop),
        ]
      ),
    ])
  }

  test("index expressions") {
    runCompilerTests([
      CompilerTestCase(
        input: "[1, 2, 3][1 + 1]",
        expectedConstants: [1, 2, 3, 1, 1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.constant, [2]),
          make(.array, [3]),
          make(.constant, [3]),
          make(.constant, [4]),
          make(.add),
          make(.index),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "{1: 2}[2 - 1]",
        expectedConstants: [1, 2, 2, 1],
        expectedInstructions: [
          make(.constant, [0]),
          make(.constant, [1]),
          make(.hash, [2]),
          make(.constant, [2]),
          make(.constant, [3]),
          make(.sub),
          make(.index),
          make(.pop),
        ]
      ),
    ])
  }

  test("functions") {
    runCompilerTests([
      CompilerTestCase(
        input: "fn() { return 5 + 10 }",
        expectedConstants: [
          5,
          10,
          [
            make(.constant, [0]),
            make(.constant, [1]),
            make(.add),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [2, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "fn() { 5 + 10 }",
        expectedConstants: [
          5,
          10,
          [
            make(.constant, [0]),
            make(.constant, [1]),
            make(.add),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [2, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "fn() { 1; 2 }",
        expectedConstants: [
          1,
          2,
          [
            make(.constant, [0]),
            make(.pop),
            make(.constant, [1]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [2, 0]),
          make(.pop),
        ]
      ),
    ])
  }

  test("functions without return value") {
    runCompilerTests([
      CompilerTestCase(
        input: "fn() { }",
        expectedConstants: [[make(.return)]],
        expectedInstructions: [make(.closure, [0, 0]), make(.pop)]
      )
    ])
  }

  test("compiler scopes") {
    let compiler = Compiler()
    guard compiler.scopeIndex == 0 else {
      Test.pushFail("scopeIndex wrong. got=\(compiler.scopeIndex), want=0")
      return
    }
    let globalSymbolTable = compiler.symbolTable

    compiler.emit(opcode: .mul)
    compiler.enterScope()
    guard compiler.scopeIndex == 1 else {
      Test.pushFail("scopeIndex wrong. got=\(compiler.scopeIndex), want=1")
      return
    }

    compiler.emit(opcode: .sub)
    guard compiler.instructions.count == 1 else {
      Test.pushFail("instructions length wrong, got=\(compiler.instructions.count), want=1")
      return
    }

    var last = compiler.lastInstruction
    guard last.opcode == .sub else {
      Test.pushFail("lastInstruction.opcode wrong. got=\(last.opcode), want=\(OpCode.sub)")
      return
    }

    guard compiler.symbolTable.outer === globalSymbolTable else {
      Test.pushFail("compiler did not enclose symboltable")
      return
    }

    _ = compiler.leaveScope()
    guard compiler.scopeIndex == 0 else {
      Test.pushFail("scopeIndex wrong. got=\(compiler.scopeIndex), want=0")
      return
    }

    guard compiler.symbolTable === globalSymbolTable else {
      Test.pushFail("compiler did not restore global symbol table")
      return
    }

    guard compiler.symbolTable.outer == nil else {
      Test.pushFail("compiler modified global symbol table incorrectly")
      return
    }

    compiler.emit(opcode: .add)
    guard compiler.instructions.count == 2 else {
      Test.pushFail("instructions length wrong, got=\(compiler.instructions.count), want=2")
      return
    }

    last = compiler.lastInstruction
    guard last.opcode == .add else {
      Test.pushFail("lastInstruction.opcode wrong. got=\(last.opcode), want=\(OpCode.add)")
      return
    }

    let prev = compiler.previousInstruction
    guard prev.opcode == .mul else {
      Test.pushFail("lastInstruction.opcode wrong. got=\(last.opcode), want=\(OpCode.mul)")
      return
    }
  }

  test("function calls") {
    runCompilerTests([
      CompilerTestCase(
        input: "fn() { 24 }();",
        expectedConstants: [
          24,
          [
            make(.constant, [0]),  // the literal 24
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [1, 0]),  // the compiled function
          make(.call, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          let noArg = fn() { 24 };
          noArg();
          """,
        expectedConstants: [
          24,
          [
            make(.constant, [0]),  // the literal 24
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [1, 0]),  // the compiled function
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.call, [0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          let oneArg = fn(a) { a };
          oneArg(24);
          """,
        expectedConstants: [
          [
            make(.getLocal, [0]),
            make(.returnValue),
          ],
          24,
        ],
        expectedInstructions: [
          make(.closure, [0, 0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.constant, [1]),
          make(.call, [1]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          let manyArg = fn(a, b, c) { a; b; c };
          manyArg(24, 25, 26);
          """,
        expectedConstants: [
          [
            make(.getLocal, [0]),
            make(.pop),
            make(.getLocal, [1]),
            make(.pop),
            make(.getLocal, [2]),
            make(.returnValue),
          ],
          24,
          25,
          26,
        ],
        expectedInstructions: [
          make(.closure, [0, 0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.constant, [1]),
          make(.constant, [2]),
          make(.constant, [3]),
          make(.call, [3]),
          make(.pop),
        ]
      ),
    ])
  }

  test("let statement scopes") {
    runCompilerTests([
      CompilerTestCase(
        input: "let num = 55; fn() { num }",
        expectedConstants: [
          55,
          [make(.getGlobal, [0]), make(.returnValue)],
        ],
        expectedInstructions: [
          make(.constant, [0]),
          make(.setGlobal, [0]),
          make(.closure, [1, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          fn () {
            let num = 55;
            num
          }
          """,
        expectedConstants: [
          55,
          [
            make(.constant, [0]),
            make(.setLocal, [0]),
            make(.getLocal, [0]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [1, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          fn() {
            let a = 55;
            let b = 77;
            a + b
          }
          """,
        expectedConstants: [
          55,
          77,
          [
            make(.constant, [0]),
            make(.setLocal, [0]),
            make(.constant, [1]),
            make(.setLocal, [1]),
            make(.getLocal, [0]),
            make(.getLocal, [1]),
            make(.add),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [2, 0]),
          make(.pop),
        ]
      ),
    ])
  }

  test("builtins") {
    runCompilerTests([
      CompilerTestCase(
        input: """
          len([]);
          push([], 1);
          """,
        expectedConstants: [1],
        expectedInstructions: [
          make(.getBuiltIn, [0]),
          make(.array, [0]),
          make(.call, [1]),
          make(.pop),
          make(.getBuiltIn, [5]),
          make(.array, [0]),
          make(.constant, [0]),
          make(.call, [2]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: "fn() { len([]) }",
        expectedConstants: [
          [
            make(.getBuiltIn, [0]),
            make(.array, [0]),
            make(.call, [1]),
            make(.returnValue),
          ]
        ],
        expectedInstructions: [
          make(.closure, [0, 0]),
          make(.pop),
        ]
      ),
    ])
  }

  test("closures") {
    runCompilerTests([
      CompilerTestCase(
        input: """
          fn(a) {
            fn(b) {
              a + b
            }
          }
          """,
        expectedConstants: [
          [
            make(.getFree, [0]),
            make(.getLocal, [0]),
            make(.add),
            make(.returnValue),
          ],
          [
            make(.getLocal, [0]),
            make(.closure, [0, 1]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [1, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          fn(a) {
            fn(b) {
              fn(c) {
                a + b + c
              }
            }
          }
          """,
        expectedConstants: [
          [
            make(.getFree, [0]),
            make(.getFree, [1]),
            make(.add),
            make(.getLocal, [0]),
            make(.add),
            make(.returnValue),
          ],
          [
            make(.getFree, [0]),
            make(.getLocal, [0]),
            make(.closure, [0, 2]),
            make(.returnValue),
          ],
          [
            make(.getLocal, [0]),
            make(.closure, [1, 1]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [2, 0]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        // finish changing over this test from page 249
        input: """
          let global = 55;

          fn() {
            let a = 66;

            fn() {

              let b = 77;

              fn() {
                let c = 88;

                global + a + b + c;
              }
            }
          }
          """,
        expectedConstants: [
          55,
          66,
          77,
          88,
          [
            make(.constant, [3]),
            make(.setLocal, [0]),
            make(.getGlobal, [0]),
            make(.getFree, [0]),
            make(.add),
            make(.getFree, [1]),
            make(.add),
            make(.getLocal, [0]),
            make(.add),
            make(.returnValue),
          ],
          [
            make(.constant, [2]),
            make(.setLocal, [0]),
            make(.getFree, [0]),
            make(.getLocal, [0]),
            make(.closure, [4, 2]),
            make(.returnValue),
          ],
          [
            make(.constant, [1]),
            make(.setLocal, [0]),
            make(.getLocal, [0]),
            make(.closure, [5, 1]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.constant, [0]),
          make(.setGlobal, [0]),
          make(.closure, [6, 0]),
          make(.pop),
        ]
      ),
    ])
  }

  test("recursive functions") {
    runCompilerTests([
      CompilerTestCase(
        input: """
          let countDown = fn(x) { countDown(x - 1); };
          countDown(1);
          """,
        expectedConstants: [
          1,
          [
            make(.currentClosure),
            make(.getLocal, [0]),
            make(.constant, [0]),
            make(.sub),
            make(.call, [1]),
            make(.returnValue),
          ],
          1,
        ],
        expectedInstructions: [
          make(.closure, [1, 0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.constant, [2]),
          make(.call, [1]),
          make(.pop),
        ]
      ),
      CompilerTestCase(
        input: """
          let wrapper = fn() {
            let countDown = fn(x) { countDown(x - 1); };
            countDown(1);
          };
          wrapper();
          """,
        expectedConstants: [
          1,
          [
            make(.currentClosure),
            make(.getLocal, [0]),
            make(.constant, [0]),
            make(.sub),
            make(.call, [1]),
            make(.returnValue),
          ],
          1,
          [
            make(.closure, [1, 0]),
            make(.setLocal, [0]),
            make(.getLocal, [0]),
            make(.constant, [2]),
            make(.call, [1]),
            make(.returnValue),
          ],
        ],
        expectedInstructions: [
          make(.closure, [3, 0]),
          make(.setGlobal, [0]),
          make(.getGlobal, [0]),
          make(.call, [0]),
          make(.pop),
        ]
      ),
    ])
  }

  return Test.report()
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
  var index = -1
  for (expected, actual) in zip(expectedConstants, actualConstants) {
    index += 1
    switch expected {
      case let int as Int:
        expect(actual).toBeObject(int: int)
      case let string as String:
        expect(actual).toBeObject(string: string)
      case let instructions as [Instructions]:
        guard let compiledFn = expect(actual).toBe(CompiledFunction.self) else {
          return "constant \(index) is not a function"
        }
        if let err = testInstructions(instructions, compiledFn.instructions) {
          return err
        }
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
