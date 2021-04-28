typealias VmTestCase = (String, Any)

func testVm() -> Bool {
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

  test("calling functions without arguments") {
    runVmTests([
      (
        """
        let fivePlusTen = fn() { 5 + 10; };
        fivePlusTen();
        """,
        15
      ),
      (
        """
        let one = fn() { 1; };
        let two = fn() { 2; };
        one() + two();
        """,
        3
      ),
      (
        """
        let a = fn() { 1 };
        let b = fn() { a() + 1 };
        let c = fn() { b() + 1 };
        c();
        """,
        3
      ),
    ])
  }

  test("calling functions with return statement") {
    runVmTests([
      (
        """
        let earlyExit = fn() { return 99; 100; };
        earlyExit();
        """,
        99
      ),
      (
        """
        let earlyExit = fn() { return 99; return 100; };
        earlyExit();
        """,
        99
      ),
    ])
  }

  test("functions without return value") {
    runVmTests([
      (
        """
        let noReturn = fn() { };
        noReturn();
        """,
        Null
      ),
      (
        """
        let noReturn = fn() { };
        let noReturnTwo = fn() { noReturn(); };
        noReturn();
        noReturnTwo();
        """,
        Null
      ),
    ])

    test("first-class functions") {
      runVmTests([
        (
          """
          let returnsOne = fn() { 1; };
          let returnsOneReturner = fn() { returnsOne; };
          returnsOneReturner()();
          """,
          1
        ),
        (
          """
          let returnsOneReturner = fn() {
            let returnsOne = fn() { 1; };
            returnsOne;
          };
          returnsOneReturner()();
          """,
          1
        ),
      ])
    }
  }

  test("calling functions with bindings") {
    runVmTests([
      (
        """
        let one = fn() { let one = 1; one };
        one();
        """,
        1
      ),
      (
        """
        let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
        oneAndTwo();
        """,
        3
      ),
      (
        """
        let oneAndTwo = fn() { let one = 1; let two = 2; one + two; };
        let threeAndFour = fn() { let three = 3; let four = 4; three + four; };
        oneAndTwo() + threeAndFour();
        """,
        10
      ),
      (
        """
        let firstFoobar = fn() { let foobar = 50; foobar; };
        let secondFoobar = fn() { let foobar = 100; foobar; };
        firstFoobar() + secondFoobar();
        """,
        150
      ),
      (
        """
        let globalSeed = 50;
        let minusOne = fn() {
          let num = 1;
          globalSeed - num;
        }
        let minusTwo = fn() {
          let num = 2;
          globalSeed - num;
        }
        minusOne() + minusTwo();
        """,
        97
      ),

    ])
  }

  test("calling functions with arguments and bindings") {
    runVmTests([
      (
        """
        let identity = fn(a) { a; };
        identity(4);
        """,
        4
      ),
      (
        """
        let sum = fn(a, b) { a + b; };
        sum(1, 2);
        """,
        3
      ),
      (
        """
        let sum = fn(a, b) {
          let c = a + b;
          c;
        };
        sum(1, 2);
        """,
        3
      ),
      (
        """
        let sum = fn(a, b) {
          let c = a + b;
          c;
        };
        sum(1, 2) + sum(3, 4);
        """,
        10
      ),
      (
        """
        let sum = fn(a, b) {
        let c = a + b;
          c;
        };
        let outer = fn() {
          sum(1, 2) + sum(3, 4);
        };
        outer();
        """,
        10
      ),
      (
        """
        let globalNum = 10;
        let sum = fn(a, b) {
          let c = a + b;
          c + globalNum;
        };
        let outer = fn() {
          sum(1, 2) + sum(3, 4) + globalNum;
        };
        outer() + globalNum;
        """,
        50
      ),
    ])
  }

  test("calling functions with wrong arguments") {
    runVmTests([
      (
        "fn() { 1; }(1);",
        VirtualMachineError.fnArity(0, 1)
      ),
      (
        "fn(a) { a; }();",
        VirtualMachineError.fnArity(1, 0)
      ),
      (
        "fn(a, b) { a + b; }(1);",
        VirtualMachineError.fnArity(2, 1)
      ),
    ])
  }

  test("built in functions") {
    runVmTests([
      (#"len("")"#, 0),
      (#"len("four")"#, 4),
      (#"len("hello world")"#, 11),
      (#"len([1, 2, 3])"#, 3),
      // (#"puts("hello", "world")"#, Null), // <-- causes test output
      (#"first([1, 2, 3])"#, 1),
      (#"last([1, 2, 3])"#, 3),
      (#"last([])"#, Null),
      (#"first([])"#, Null),
      (#"rest([])"#, Null),
      (#"push([], 1)"#, [1]),
      (#"rest([1, 2, 3])"#, [2, 3]),
      (
        "len(1)",
        Error("argument to `len` not supported, got=INTEGER")
      ),
      (
        #"len("one", "two")"#,
        Error("wrong number of arguments, got=2, want=1")
      ),
      (
        #"len("one", "two")"#,
        Error("wrong number of arguments, got=2, want=1")
      ),
      (
        #"first(1)"#,
        Error("argument to `first` must be ARRAY, got INTEGER")
      ),
      (
        #"last(1)"#,
        Error("argument to `last` must be ARRAY, got INTEGER")
      ),
      (
        #"push(1, 1)"#,
        Error("argument to `push` must be ARRAY, got INTEGER")
      ),
    ])
  }

  return Test.report()
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
      guard let expectedErr = expected as? VirtualMachineError else {
        Test.pushFail("unexpected vm error: \(err)")
        return
      }
      expect(err.description).toEqual(expectedErr.description)
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
      case let errObj as Error:
        expect(vm.lastPoppedStackElem).toBeObject(error: errObj.message)
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
