enum SymbolScope: String {
  case global = "GLOBAL"
}

struct Symbol: Equatable {
  var name: String
  var scope: SymbolScope
  var index: Int
}

class SymbolTable {
  private var store: [String: Symbol] = [:]
  private var numDefinitions: Int = 0

  @discardableResult
  func define(name: String) -> Symbol {
    let symbol = Symbol(name: name, scope: .global, index: numDefinitions)
    store[name] = symbol
    numDefinitions += 1
    return symbol
  }

  func resolve(name: String) -> Symbol? {
    return store[name]
  }
}
