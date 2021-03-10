enum ObjectType: String, CustomStringConvertible {
  case integer
  case boolean
  case null
  case error

  var description: String {
    return self.rawValue.uppercased()
  }
}

protocol Object: CustomStringConvertible {
  var type: ObjectType { get }
  var inspect: String { get }
}

extension Object {
  var description: String { inspect }
}

struct Integer: Object {
  var value: Int
  var type = ObjectType.integer
  var inspect: String { "\(self.value)" }
}

// Boolean is a class for sharing reference-semantic true/false singletons
class Boolean: Object {
  var value: Bool
  var type = ObjectType.boolean
  var inspect: String { "\(self.value)" }

  static let `true` = Boolean(value: true)
  static let `false` = Boolean(value: false)

  static func from(_ bool: Bool) -> Boolean {
    return bool ? .true : .false
  }

  init(value: Bool) {
    self.value = value
  }
}

class NullObject: Object {
  var value: Void = ()
  var type = ObjectType.null
  var inspect: String { "null" }
}

// shared reference-semantic null singleton
let Null = NullObject()

struct Error: Object {
  var value: String
  var type = ObjectType.error
  var inspect: String { "\(self.value)" }

  init(_ msg: String) {
    self.value = msg
  }
}
