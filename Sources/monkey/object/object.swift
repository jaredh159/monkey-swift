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

struct Boolean: Object {
  var value: Bool
  var type = ObjectType.boolean
  var inspect: String { "\(self.value)" }
}

struct Null: Object {
  var value: Void = ()
  var type = ObjectType.null
  var inspect: String { "null" }
}

struct Error: Object {
  var value: String
  var type = ObjectType.error
  var inspect: String { "\(self.value)" }

  init(_ msg: String) {
    self.value = msg
  }
}
