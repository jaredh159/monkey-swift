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

  test("hash literals") {
    let cases: [(String, [HashKey: Int])] = [
      ("{}", [:]),
      (
        "{1: 2, 2: 3}",
        [
          HashKey(Integer(value: 1))!: 2,
          HashKey(Integer(value: 2))!: 3,
        ]
      ),
      (
        "{1 + 1: 2 * 2, 3 + 3: 4 * 4}",
        [
          HashKey(Integer(value: 2))!: 4,
          HashKey(Integer(value: 6))!: 16,
        ]
      ),
    ]
    runVmTests(cases)
  }

  test("index expressions") {
    let cases: [VmTestCase] = [
      ("[1, 2, 3][1]", 2),
      ("[1, 2, 3][0 + 2]", 3),
      ("[[1, 1, 1]][0][0]", 1),
      ("[][0]", Null),
      ("[1, 2, 3][99]", Null),
      ("[1][-1]", Null),
      ("{1: 1, 2: 2}[1]", 1),
      ("{1: 1, 2: 2}[2]", 2),
      ("{1: 1}[0]", Null),
      ("{}[0]", Null),
    ]
    runVmTests(cases)
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
      case let hashMap as [HashKey: Int]:
        let last = vm.lastPoppedStackElem
        guard let hashObj = last as? Hash else {
          Test.pushFail("object not Hash: \(String(describing: last)) \(type(of: last))")
          return
        }
        guard expect(hashObj.pairs.count).toEqual(hashMap.count) else {
          return
        }
        for (actualKey, actualVal) in hashObj.pairs {
          expect(hashMap[actualKey]).toEqual((actualVal.value as! Integer).value)
        }
      default:
        Test.pushFail("unhandled vm test type: \(type(of: expected))")
    }
  }
}
