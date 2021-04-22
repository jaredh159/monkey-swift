func testSymbolTable() -> Bool {
  Test.reset(suiteName: "SymbolTable")

  test("define global") {
    let global = SymbolTable()
    let a = global.define(name: "a")
    expect(a).toEqual(Symbol(name: "a", scope: .global, index: 0))
    let b = global.define(name: "b")
    expect(b).toEqual(Symbol(name: "b", scope: .global, index: 1))
  }

  test("resolve global") {
    let global = SymbolTable()
    global.define(name: "a")
    global.define(name: "b")
    let a = global.resolve(name: "a")
    expect(a).toEqual(Symbol(name: "a", scope: .global, index: 0))
    let b = global.resolve(name: "b")
    expect(b).toEqual(Symbol(name: "b", scope: .global, index: 1))
  }

  test("define global and local") {
    let expected: [String: Symbol] = [
      "a": Symbol(name: "a", scope: .global, index: 0),
      "b": Symbol(name: "b", scope: .global, index: 1),
      "c": Symbol(name: "c", scope: .local, index: 0),
      "d": Symbol(name: "d", scope: .local, index: 1),
      "e": Symbol(name: "e", scope: .local, index: 0),
      "f": Symbol(name: "f", scope: .local, index: 1),
    ]

    let global = SymbolTable()

    let a = global.define(name: "a")
    if a != expected["a"] {
      Test.pushFail("expected a=\(expected["a"]!), got=\(a)")
    }

    let b = global.define(name: "b")
    if b != expected["b"] {
      Test.pushFail("expected b=\(expected["b"]!), got=\(b)")
    }

    let firstLocal = SymbolTable(enclosedBy: global)

    let c = firstLocal.define(name: "c")
    if c != expected["c"] {
      Test.pushFail("expected c=\(expected["c"]!), got=\(c)")
    }

    let d = firstLocal.define(name: "d")
    if d != expected["d"] {
      Test.pushFail("expected d=\(expected["d"]!), got=\(d)")
    }

    let secondLocal = SymbolTable(enclosedBy: firstLocal)

    let e = secondLocal.define(name: "e")
    if e != expected["e"] {
      Test.pushFail("expected e=\(expected["e"]!), got=\(e)")
    }

    let f = secondLocal.define(name: "f")
    if f != expected["f"] {
      Test.pushFail("expected f=\(expected["f"]!), got=\(f)")
    }
  }

  test("resolve local") {
    let global = SymbolTable()
    global.define(name: "a")
    global.define(name: "b")
    let local = SymbolTable(enclosedBy: global)
    local.define(name: "c")
    local.define(name: "d")

    let cases: [Symbol] = [
      Symbol(name: "a", scope: .global, index: 0),
      Symbol(name: "b", scope: .global, index: 1),
      Symbol(name: "c", scope: .local, index: 0),
      Symbol(name: "d", scope: .local, index: 1),
    ]
    for expectedSymbol in cases {
      guard let result = local.resolve(name: expectedSymbol.name) else {
        Test.pushFail("name \(expectedSymbol.name) not resolvable")
        continue
      }
      guard expectedSymbol == result else {
        Test.pushFail("expected a=\(expectedSymbol), got=\(result)")
        continue
      }
      Test.pushPass()
    }
  }

  test("resolve nested local") {
    let global = SymbolTable()
    global.define(name: "a")
    global.define(name: "b")
    let firstLocal = SymbolTable(enclosedBy: global)
    firstLocal.define(name: "c")
    firstLocal.define(name: "d")
    let secondLocal = SymbolTable(enclosedBy: firstLocal)
    secondLocal.define(name: "e")
    secondLocal.define(name: "f")

    let tests: [(SymbolTable, [Symbol])] = [
      (
        firstLocal,
        [
          Symbol(name: "a", scope: .global, index: 0),
          Symbol(name: "b", scope: .global, index: 1),
          Symbol(name: "c", scope: .local, index: 0),
          Symbol(name: "d", scope: .local, index: 1),
        ]
      ),
      (
        secondLocal,
        [
          Symbol(name: "a", scope: .global, index: 0),
          Symbol(name: "b", scope: .global, index: 1),
          Symbol(name: "e", scope: .local, index: 0),
          Symbol(name: "f", scope: .local, index: 1),
        ]
      ),
    ]
    for (table, expectedSymbols) in tests {
      for expectedSymbol in expectedSymbols {
        guard let result = table.resolve(name: expectedSymbol.name) else {
          Test.pushFail("name \(expectedSymbol.name) not resolvable")
          continue
        }
        guard expectedSymbol == result else {
          Test.pushFail("unexpected symbol for name: \(expectedSymbol.name)")
          continue
        }
        Test.pushPass()
      }
    }
  }

  return Test.report()
}
