class Environment {
  private var store: [String: Object] = [:]

  func get(_ name: String) -> Object? {
    return store[name]
  }

  @discardableResult
  func set(_ name: String, _ value: Object) -> Object {
    store[name] = value
    return value
  }
}
