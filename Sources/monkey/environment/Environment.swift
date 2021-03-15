class Environment {
  private var store: [String: Object] = [:]
  private var outer: Environment?

  func get(_ name: String) -> Object? {
    return store[name] ?? outer?.get(name)
  }

  @discardableResult
  func set(_ name: String, _ value: Object) -> Object {
    store[name] = value
    return value
  }

  init() {}

  init(enclosedBy outer: Environment) {
    self.outer = outer
  }
}
