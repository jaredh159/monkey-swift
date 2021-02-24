extension String {
  var red: String {
    return "\u{001B}[0;31m" + self + "\u{001B}[0;0m"
  }
  var green: String {
    return "\u{001B}[0;32m" + self + "\u{001B}[0;0m"
  }
}

  //  case black = "\u{001B}[0;30m"
  //   case red = "\u{001B}[0;31m"
  //   case green = "\u{001B}[0;32m"
  //   case yellow = "\u{001B}[0;33m"
  //   case blue = "\u{001B}[0;34m"
  //   case magenta = "\u{001B}[0;35m"
  //   case cyan = "\u{001B}[0;36m"
  //   case white = "\u{001B}[0;37m"
