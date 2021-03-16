var MonkeyBuiltins: [String: BuiltIn] = [
  "len": BuiltIn { (_ args: [Object]) in
    if args.count != 1 {
      return Error("wrong number of arguments, got=\(args.count), want=1")
    }
    switch args.first {
      case let string as StringObject:
        return Integer(value: string.value.count)
      default:
        return Error("argument to `len` not supported, got=\(args.first.type)")
    }
  }
]
