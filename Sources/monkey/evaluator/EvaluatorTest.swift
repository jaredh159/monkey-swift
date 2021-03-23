func testEval() {
  Test.reset(suiteName: "EvaluatorTest")

  test("eval integer expression") {
    let cases = [
      ("5", 5),
      ("10", 10),
      ("-5", -5),
      ("-10", -10),
      ("5 + 5 + 5 + 5 - 10", 10),
      ("2 * 2 * 2 * 2 * 2", 32),
      ("-50 + 100 + -50", 0),
      ("5 * 2 + 10", 20),
      ("5 + 2 * 10", 25),
      ("20 + 2 * -10", 0),
      ("50 / 2 * 2 + 10", 60),
      ("2 * (5 + 10)", 30),
      ("3 * 3 * 3 + 10", 37),
      ("3 * (3 * 3) + 10", 37),
      ("(5 + 10 * 2 + 15 / 3) * 2 + -10", 50),
    ]
    cases.forEach { (input, expected) in
      let evaluated = testEval(input)
      expect(evaluated).toBeObject(int: expected)
    }
  }

  test("eval boolean expression") {
    let cases = [
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
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(bool: expected)
    }
  }

  test("bang operator") {
    let cases = [
      ("!false", true),
      ("!5", false),
      ("!!true", true),
      ("!!false", false),
      ("!!5", true),
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(bool: expected)
    }
  }

  test("if else expressions") {
    let cases = [
      ("if (true) { 10 }", 10),
      ("if (false) { 10 }", nil),
      ("if (1) { 10 }", 10),
      ("if (1 < 2) { 10 }", 10),
      ("if (1 > 2) { 10 }", nil),
      ("if (1 > 2) { 10 } else { 20 }", 20),
      ("if (1 < 2) { 10 } else { 20 }", 10),
    ]
    cases.forEach { (input, expected) in
      let result = testEval(input)
      if let int = expected {
        expect(result).toBeObject(int: int)
      } else {
        expect(result).toBeNull()
      }
    }
  }

  test("return statements") {
    let cases = [
      ("return 10;", 10),
      ("return 10; 9;", 10),
      ("return 2 * 5; 9;", 10),
      ("9; return 2 * 5; 9;", 10),
      (
        """
        if (10 > 1) {
          if (10 > 1) {
            return 10;
          }
          return 1;
        }
        """,
        10
      ),
    ]
    cases.forEach { (input, expected) in
      expect(testEval(input)).toBeObject(int: expected)
    }
  }

  test("error handling") {
    let cases = [
      (
        "5 + true;",
        "type mismatch: INTEGER + BOOLEAN"
      ),
      (
        "5 + true; 5;",
        "type mismatch: INTEGER + BOOLEAN"
      ),
      (
        "-true",
        "unknown operator: -BOOLEAN"
      ),
      (
        "true + false;",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "5; true + false; 5",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "if (10 > 1) { true + false; }",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "if (10 > 1) { if (10 > 1) { return true + false } return 1 }",
        "unknown operator: BOOLEAN + BOOLEAN"
      ),
      (
        "foobar",
        "identifier not found: foobar"
      ),
      (
        #""Hello" - "World""#,
        "unknown operator: STRING - STRING"
      ),
      (
        #"{"name": "Monkey"}[fn(x) { x }];"#,
        "unusable as hash key: FUNCTION"
      ),
    ]
    cases.forEach { (input, expectedError) in
      expect(testEval(input)).toBeObject(error: expectedError)

    }
  }

  test("let statements") {
    let cases = [
      ("let a = 5; a;", 5),
      ("let a = 5 * 5; a;", 25),
      ("let a = 5; let b = a; b;", 5),
      ("let a = 5; let b = a; let c = a + b + 5; c;", 15),
    ]
    cases.forEach { (input, expectedInt) in
      expect(testEval(input)).toBeObject(int: expectedInt)
    }
  }

  test("function object") {
    let input = "fn(x) { x + 2; };"
    let evaluated = testEval(input)
    guard let fn = expect(evaluated).toBe(Function.self) else {
      return
    }
    guard expect(fn.parameters.count).toEqual(1) else {
      return
    }
    guard expect(fn.parameters.first?.string).toEqual("x") else {
      return
    }
    expect(fn.body.string).toEqual("(x + 2)")
  }

  test("function application") {
    let cases = [
      ("let identity = fn(x) { x; }; identity(5);", 5),
      ("let identity = fn(x) { return x; }; identity(5);", 5),
      ("let double = fn(x) { x * 2; }; double(5);", 10),
      ("let add = fn(x, y) { x + y; }; add(5, 5);", 10),
      ("let add = fn(x, y) { x + y; }; add(5 + 5, add(5, 5));", 20),
      ("fn(x) { x; }(5)", 5),
    ]
    cases.forEach({ input, expectedInt in
      expect(testEval(input)).toBeObject(int: expectedInt)
    })
  }

  test("closures") {
    let input = """
      let newAdder = fn(x) {
        fn(y) { x + y };
      };
      let addTwo = newAdder(2);
      addTwo(2);
      """
    expect(testEval(input)).toBeObject(int: 4)
  }

  test("string literal") {
    let input = "\"Hello World!\""
    expect(testEval(input)).toBeObject(string: "Hello World!")
  }

  test("string concatenation") {
    let input = "\"Hello\" + \" \" + \"World!\""
    expect(testEval(input)).toBeObject(string: "Hello World!")
  }

  test("builtin functions") {
    let cases: [(String, Any?)] = [
      ("len(\"\")", 0),
      ("len(\"four\")", 4),
      ("len(\"hello world\")", 11),
      ("len([1, 2, 3])", 3),
      ("len([])", 0),
      ("first([1, 2, 3])", 1),
      ("first([])", nil),
      ("last([1, 2, 3])", 3),
      ("last([])", nil),
      ("first(rest([1, 2, 3]))", 2),
      ("first(rest([1]))", nil),
      ("last(push([1, 2], 3)", 3),
      ("first(push([1, 2], 3)", 1),
      ("len(1)", "argument to `len` not supported, got=INTEGER"),
      ("len(\"one\", \"two\")", "wrong number of arguments, got=2, want=1"),
    ]
    cases.forEach { (input, expected) in
      let evaluated = testEval(input)
      switch expected {
        case let intVal as Int:
          expect(evaluated).toBeObject(int: intVal)
        case let errMsg as String:
          expect(evaluated).toBeObject(error: errMsg)
        case nil:
          expect(evaluated).toBeNull()
        default:
          break
      }
    }
  }

  test("array literals") {
    let evaluated = testEval("[1, 2 * 2, 3 + 3]")
    guard let array = expect(evaluated).toBe(ArrayObject.self) else {
      return
    }
    guard expect(array.elements.count).toEqual(3) else {
      return
    }
    expect(array.elements[0]).toBeObject(int: 1)
    expect(array.elements[1]).toBeObject(int: 4)
    expect(array.elements[2]).toBeObject(int: 6)
  }

  test("array index expressions") {
    let cases = [
      (
        "[1, 2, 3][0]",
        1
      ),
      (
        "[1, 2, 3][1]",
        2
      ),
      (
        "[1, 2, 3][2]",
        3
      ),
      (
        "let i = 0; [1][i];",
        1
      ),
      (
        "[1, 2, 3][1 + 1];",
        3
      ),
      (
        "let myArray = [1, 2, 3]; myArray[2];",
        3
      ),
      (
        "let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];",
        6
      ),
      (
        "let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]",
        2
      ),
      (
        "[1, 2, 3][3]",
        nil
      ),
      (
        "[1, 2, 3][-1]",
        nil
      ),
    ]
    cases.forEach { (input, expectedInt) in
      let evaluated = testEval(input)
      if let int = expectedInt {
        expect(evaluated).toBeObject(int: int)
      } else {
        expect(evaluated).toBeNull()
      }
    }
  }

  test("hash literals") {
    let input = """
      let two = "two";
      {
        "one": 10 - 9,
        two: 1 + 1,
        "thr" + "ee": 6 / 2,
        4: 4,
        true: 5,
        false: 6
      }
      """
    let evaluated = testEval(input)
    guard let hash = expect(evaluated).toBe(Hash.self) else {
      return
    }
    let cases: [(HashKey?, Int)] = [
      (HashKey(StringObject(value: "one")), 1),
      (HashKey(StringObject(value: "two")), 2),
      (HashKey(StringObject(value: "three")), 3),
      (HashKey(Integer(value: 4)), 4),
      (HashKey(Boolean.true), 5),
      (HashKey(Boolean.false), 6),
    ]
    guard expect(cases.count).toEqual(hash.pairs.count) else {
      return
    }

    cases.forEach { (hashKey, expectedRhs) in
      expect(hash.pairs[hashKey!]?.value).toBeObject(int: expectedRhs)
    }
  }

  test("hash index expressions") {
    let cases = [
      (#"{"foo": 5}["foo"]"#, 5),
      (#"{"foo": 5}["bar"]"#, nil),
      (#"let key = "foo"; {"foo": 5}[key]"#, 5),
      (#"{}["foo"]"#, nil),
      (#"{5: 5}[5]"#, 5),
      (#"{true: 5}[true]"#, 5),
      (#"{false: 5}[false]"#, 5),
    ]
    cases.forEach { (input, expected) in
      let evaluated = testEval(input)
      if let expected = expected {
        expect(evaluated).toBeObject(int: expected)
      } else {
        expect(evaluated).toBeNull()
      }
    }
  }

  Test.report()
}

func testEval(_ input: String) -> Object? {
  let parser = Parser(Lexer(input))
  let program = parser.parseProgram()
  return eval(program, Environment())
}
