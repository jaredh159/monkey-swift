typealias VmTestCase = (String, Any)

func testVm() {
  Test.reset(suiteName: "VirtualMachine")

  test("integer arithmetic") {
    let cases: [VmTestCase] = [
      ("1", 1),
      ("2", 2),
      ("1 + 2", 2),  // FIXME
    ]
    runVmTests(cases)
  }

  Test.report()
}

func runVmTests(_ tests: [VmTestCase]) {
  tests.forEach { (input, expected) in
    let program = parse(input)
    var compiler = Compiler()
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
        expect(vm.stackTop).toBeObject(int: int)
      default:
        Test.pushFail("unhandled vm test type: \(type(of: expected))")
    }
  }
}
