enum BuiltIns: String, CaseIterable {
  case len
  case puts
  case first
  case last
  case rest
  case push

  init?(from index: Int) {
    if BuiltIns.allCases.indices.contains(index) {
      self = BuiltIns.allCases[index]
    } else {
      return nil
    }
  }

  func object() -> BuiltIn {
    switch self {
      case .len:
        return BuiltIn { args in
          if args.count != 1 {
            return Error("wrong number of arguments, got=\(args.count), want=1")
          }
          switch args.first {
            case let string as StringObject:
              return Integer(value: string.value.count)
            case let array as ArrayObject:
              return Integer(value: array.elements.count)
            default:
              return Error("argument to `len` not supported, got=\(args.first.type)")
          }
        }

      case .puts:
        return BuiltIn { args in
          args.forEach { print($0.inspect) }
          return Null
        }

      case .first:
        return BuiltIn { args in
          if args.count != 1 {
            return Error("wrong number of arguments, got=\(args.count), want=1")
          }
          guard let array = args.first as? ArrayObject else {
            return Error("argument to `first` must be ARRAY, got \(args.first.type)")
          }
          return array.elements.first ?? Null
        }

      case .last:
        return BuiltIn { args in
          if args.count != 1 {
            return Error("wrong number of arguments, got=\(args.count), want=1")
          }
          guard let array = args.first as? ArrayObject else {
            return Error("argument to `last` must be ARRAY, got \(args.first.type)")
          }
          return array.elements.last ?? Null
        }

      case .rest:
        return BuiltIn { args in
          if args.count != 1 {
            return Error("wrong number of arguments, got=\(args.count), want=1")
          }
          guard let array = args.first as? ArrayObject else {
            return Error("argument to `first` must be ARRAY, got \(args.first.type)")
          }
          if array.elements.isEmpty {
            return Null
          }
          return ArrayObject(elements: Array(array.elements.dropFirst(1)))
        }

      case .push:
        return BuiltIn { args in
          if args.count != 2 {
            return Error("wrong number of arguments, got=\(args.count), want=2")
          }
          guard let array = args.first as? ArrayObject else {
            return Error("argument to `push` must be ARRAY, got \(args.first.type)")
          }
          return ArrayObject(elements: array.elements + [args[1]])
        }
    }
  }
}
