enum ObjectType: String, CustomStringConvertible {
  case integer
  case boolean
  case null
  case error
  case builtin
  case function
  case compiledFunction
  case string
  case array
  case hash
  case returnValue = "return_value"

  var description: String {
    return self.rawValue.uppercased()
  }
}

protocol Object: CustomStringConvertible {
  var type: ObjectType { get }
  var inspect: String { get }
  var isError: Bool { get }
}

extension Object {
  var description: String { inspect }
  var isError: Bool { self.type == .error }
}

extension Optional where Wrapped == Object {
  var isError: Bool { self?.isError == true }
  var type: String {
    guard let obj = self else {
      return "Optional(nil)"
    }
    return String(describing: obj.type)
  }
}

struct StringObject: Object, Hashable {
  var value: String
  var type = ObjectType.string
  var inspect: String { value }
}

struct Integer: Object, Hashable {
  var value: Int
  var type = ObjectType.integer
  var inspect: String { "\(value)" }
}

// Boolean is a class for sharing reference-semantic true/false singletons
class Boolean: Object, Hashable {
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

  static func == (lhs: Boolean, rhs: Boolean) -> Bool {
    return lhs.value == rhs.value
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(type)
    hasher.combine(value)
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
  var message: String
  var type = ObjectType.error
  var inspect: String { "ERROR: \(self.message)" }

  init(_ message: String) {
    self.message = message
  }
}

struct ReturnValue: Object {
  var value: Object
  var type = ObjectType.returnValue
  var inspect: String { self.value.inspect }
}

struct Function: Object {
  var type = ObjectType.function
  var parameters: [Identifier] = []
  var body: BlockStatement
  var env: Environment

  var inspect: String {
    let params = parameters.map { $0.string }.joined(separator: ", ")
    return "fn(\(params)) {\n\(body.string)\n}"
  }
}

struct CompiledFunction: Object {
  var type = ObjectType.compiledFunction
  var instructions: Instructions
  var inspect: String { "CompileFunction" }
}

struct BuiltIn: Object {
  var type = ObjectType.builtin
  var fn: (_ args: [Object]) -> Object
  var inspect: String { "builtin function" }
}

struct ArrayObject: Object {
  var type = ObjectType.array
  var elements: [Object]
  var inspect: String {
    let elems = elements.map { $0.inspect }.joined(separator: ", ")
    return "[\(elems)]"
  }
}

enum HashKey: Hashable {
  case boolean(Boolean)
  case integer(Integer)
  case string(StringObject)

  init?(_ object: Object) {
    switch object {
      case let string as StringObject:
        self = .string(string)
      case let integer as Integer:
        self = .integer(integer)
      case let boolean as Boolean:
        self = .boolean(boolean)
      default:
        return nil
    }
  }
}

struct HashPair {
  var key: Object
  var value: Object
}

struct Hash: Object {
  var type = ObjectType.hash
  var pairs: [HashKey: HashPair]
  var inspect: String {
    let pairsStr = pairs.values.map { pair in
      "\(pair.key.inspect): \(pair.value.inspect)"
    }.joined(separator: ", ")
    return "{\(pairsStr)}"
  }
}

func ~= (pattern: Boolean, value: Object?) -> Bool {
  if let bool = value as? Boolean {
    return pattern.value == bool.value
  }
  return false
}

func ~= (pattern: NullObject, value: Object?) -> Bool {
  if let _ = value as? NullObject {
    return true
  }
  return false
}
