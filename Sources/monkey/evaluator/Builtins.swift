var MonkeyBuiltins: [String: BuiltIn] = [

  "len": BuiltIn { (_ args: [Object]) in
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
  },

  "first": BuiltIn { (_ args: [Object]) in
    if args.count != 1 {
      return Error("wrong number of arguments, got=\(args.count), want=1")
    }
    guard let array = args.first as? ArrayObject else {
      return Error("argument to `first` must be ARRAY, got \(args.first.type)")
    }
    return array.elements.first ?? Null
  },

  "last": BuiltIn { (_ args: [Object]) in
    if args.count != 1 {
      return Error("wrong number of arguments, got=\(args.count), want=1")
    }
    guard let array = args.first as? ArrayObject else {
      return Error("argument to `first` must be ARRAY, got \(args.first.type)")
    }
    return array.elements.last ?? Null
  },

  "rest": BuiltIn { (_ args: [Object]) in
    if args.count != 1 {
      return Error("wrong number of arguments, got=\(args.count), want=1")
    }
    guard let array = args.first as? ArrayObject else {
      return Error("argument to `first` must be ARRAY, got \(args.first.type)")
    }
    return ArrayObject(elements: Array(array.elements.dropFirst(1)))
  },

  "push": BuiltIn { (_ args: [Object]) in
    if args.count != 2 {
      return Error("wrong number of arguments, got=\(args.count), want=2")
    }
    guard let array = args.first as? ArrayObject else {
      return Error("argument to `first` must be ARRAY, got \(args.first.type)")
    }
    return ArrayObject(elements: array.elements + [args[1]])
  },
]
