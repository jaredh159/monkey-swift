enum SymbolScope: String {
  case global = "GLOBAL"
  case local = "LOCAL"
  case builtIn = "BUILTIN"
}

struct Symbol: Equatable {
  var name: String
  var scope: SymbolScope
  var index: Int
}

class SymbolTable {
  private(set) var outer: SymbolTable?
  private var store: [String: Symbol] = [:]
  private(set) var numDefinitions: Int = 0

  @discardableResult
  func define(name: String) -> Symbol {
    let scope: SymbolScope = outer == nil ? .global : .local
    let symbol = Symbol(name: name, scope: scope, index: numDefinitions)
    store[name] = symbol
    numDefinitions += 1
    return symbol
  }

  @discardableResult
  func defineBuiltIn(name: String, index: Int) -> Symbol {
    let symbol = Symbol(name: name, scope: .builtIn, index: index)
    store[name] = symbol
    return symbol
  }

  func resolve(name: String) -> Symbol? {
    return store[name] ?? outer?.resolve(name: name)
  }

  init(enclosedBy outer: SymbolTable? = nil) {
    self.outer = outer
  }
}
