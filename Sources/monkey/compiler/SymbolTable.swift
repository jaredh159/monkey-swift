enum SymbolScope: String {
  case global = "GLOBAL"
  case local = "LOCAL"
}

struct Symbol: Equatable {
  var name: String
  var scope: SymbolScope
  var index: Int
}

class SymbolTable {
  private(set) var outer: SymbolTable?
  private var store: [String: Symbol] = [:]
  private var numDefinitions: Int = 0

  @discardableResult
  func define(name: String) -> Symbol {
    let scope: SymbolScope = outer == nil ? .global : .local
    let symbol = Symbol(name: name, scope: scope, index: numDefinitions)
    store[name] = symbol
    numDefinitions += 1
    return symbol
  }

  func resolve(name: String) -> Symbol? {
    return store[name] ?? outer?.resolve(name: name)
  }

  init() {}

  init(enclosedBy outer: SymbolTable) {
    self.outer = outer
  }
}
