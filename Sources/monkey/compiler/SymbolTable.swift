enum SymbolScope: String {
  case global = "GLOBAL"
  case local = "LOCAL"
  case builtIn = "BUILTIN"
  case free = "FREE"
  case function = "FUNCTION"
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
  private(set) var freeSymbols: [Symbol] = []

  @discardableResult
  func define(name: String) -> Symbol {
    let scope: SymbolScope = outer == nil ? .global : .local
    let symbol = Symbol(name: name, scope: scope, index: numDefinitions)
    store[name] = symbol
    numDefinitions += 1
    return symbol
  }

  @discardableResult
  func defineFree(from original: Symbol) -> Symbol {
    freeSymbols.append(original)
    let free = Symbol(name: original.name, scope: .free, index: freeSymbols.count - 1)
    store[original.name] = free
    return free
  }

  @discardableResult
  func defineFunction(name: String) -> Symbol {
    let fn = Symbol(name: name, scope: .function, index: 0)
    store[name] = fn
    return fn
  }

  @discardableResult
  func defineBuiltIn(name: String, index: Int) -> Symbol {
    let symbol = Symbol(name: name, scope: .builtIn, index: index)
    store[name] = symbol
    return symbol
  }

  func resolve(name: String) -> Symbol? {
    // current scope
    if let symbol = store[name] {
      return symbol
    }

    // if we can't find it in the outer scope, return nil
    guard let outer = outer, let symbol = outer.resolve(name: name) else {
      return nil
    }

    if symbol.scope == .global || symbol.scope == .builtIn {
      return symbol
    }

    // we found the symbol in an outer scope that is NOT global or built in
    // so that means it's a "free" variable with respect to current... something
    // so we push it into the free symbols and return a copy of the original
    return defineFree(from: symbol)
  }

  init(enclosedBy outer: SymbolTable? = nil) {
    self.outer = outer
  }
}
