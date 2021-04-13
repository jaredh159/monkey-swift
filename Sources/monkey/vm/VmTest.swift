typealias VmTestCase = (String, Any)

func testVm() {
  Test.reset(suiteName: "VirtualMachine")

  test("integer arithmetic") {
    let cases: [VmTestCase] = [
      ("1", 1),
      ("2", 2),
      ("1 + 2", 3),
      ("1 - 2", -1),
      ("1 * 2", 2),
      ("4 / 2", 2),
      ("50 / 2 * 2 + 10 - 5", 55),
      ("5 + 5 + 5 + 5 - 10", 10),
      ("2 * 2 * 2 * 2 * 2", 32),
      ("5 * 2 + 10", 20),
      ("5 + 2 * 10", 25),
      ("5 * (2 + 10)", 60),
      ("-5", -5),
      ("-10", -10),
      ("-50 + 100 + -50", 0),
      ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
    ]
    runVmTests(cases)
  }

  test("boolean expressions") {
    let cases: [VmTestCase] = [
      ("true", true),
      ("false", false),
      ("1 < 2", true),
      ("1 > 2", false),
      ("1 < 1", false),
      ("1 > 1", false),
      ("1 == 1", true),
      ("1 != 1", false),
      ("1 == 2", false),
      ("1 != 2", true),
      ("true == true", true),
      ("false == false", true),
      ("true == false", false),
      ("true != false", true),
      ("false != true", true),
      ("(1 < 2) == true", true),
      ("(1 < 2) == false", false),
      ("(1 > 2) == true", false),
      ("(1 > 2) == false", true),
      ("!true", false),
      ("!false", true),
      ("!5", false),
      ("!!true", true),
      ("!!false", false),
      ("!!5", true),
      ("!(if (false) { 5; })", true),
    ]
    runVmTests(cases)
  }

  test("conditionals") {
    runVmTests([
      ("if (true) { 10 }", 10),
      ("if (true) { 10 } else { 20 }", 10),
      ("if (false) { 10 } else { 20 } ", 20),
      ("if (1) { 10 }", 10),
      ("if (1 < 2) { 10 }", 10),
      ("if (1 < 2) { 10 } else { 20 }", 10),
      ("if (1 > 2) { 10 } else { 20 }", 20),
      ("if (1 > 2) { 10 }", Null),
      ("if (false) { 10 }", Null),
      ("if ((if (false) { 10 })) { 10 } else { 20 }", 20),
    ])
  }

  test("global let statements") {
    runVmTests([
      ("let one = 1; one", 1),
      ("let one = 1; let two = 2; one + two", 3),
      ("let one = 1; let two = one + one; one + two", 3),
    ])
  }

  test("string expressions") {
    runVmTests([
      (#""monkey""#, "monkey"),
      (#""mon" + "key""#, "monkey"),
      (#""mon" + "key" + "banana""#, "monkeybanana"),
    ])
  }

  test("array literals") {
    runVmTests([
      ("[]", [] as [Int]),
      ("[1, 2, 3]", [1, 2, 3]),
      ("[1 + 2, 3 * 4, 5 + 6]", [3, 12, 11]),
    ])
  }

  Test.report()
}

func runVmTests(_ tests: [VmTestCase]) {
  tests.forEach { (input, expected) in
    let program = parse(input)
    let compiler = Compiler()
    if let err = compiler.compile(program) {
      Test.pushFail("compiler error: \(err)")
      return
    }
    let vm = VirtualMachine(compiler.bytecode())
    if let err = vm.run() {
      Test.pushFail("vm error: \(err)")
      return
    }
    switch expected {
      case let int as Int:
        expect(vm.lastPoppedStackElem).toBeObject(int: int)
      case let bool as Bool:
        expect(vm.lastPoppedStackElem).toBeObject(bool: bool)
      case _ as NullObject:
        expect(vm.lastPoppedStackElem).toBeNull()
      case let string as String:
        expect(vm.lastPoppedStackElem).toBeObject(string: string)
      case let intArray as [Int]:
        let last = vm.lastPoppedStackElem
        guard let arrayObj = last as? ArrayObject else {
          Test.pushFail("object not Array: \(String(describing: last)) \(type(of: last))")
          return
        }
        guard expect(intArray.count).toEqual(arrayObj.elements.count) else {
          return
        }
        for (actual, expected) in zip(arrayObj.elements, intArray) {
          expect(actual).toBeObject(int: expected)
        }
      default:
        Test.pushFail("unhandled vm test type: \(type(of: expected))")
    }
  }
}
