func testSymbolTable() {
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

  Test.report()
}
