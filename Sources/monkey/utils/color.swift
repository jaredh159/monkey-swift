extension String {
  var red: String {
    return ANSIColors.red.rawValue + self + ANSIColors.reset.rawValue
  }
  var magenta: String {
    return ANSIColors.magenta.rawValue + self + ANSIColors.reset.rawValue
  }
  var cyan: String {
    return ANSIColors.cyan.rawValue + self + ANSIColors.reset.rawValue
  }
  var green: String {
    return ANSIColors.green.rawValue + self + ANSIColors.reset.rawValue
  }
  var grey: String {
    return ANSIColors.gray.rawValue + self + ANSIColors.reset.rawValue
  }
  var gray: String {
    return ANSIColors.gray.rawValue + self + ANSIColors.reset.rawValue
  }
}

private enum ANSIColors: String {
  case black = "\u{001B}[0;30m"
  case red = "\u{001B}[0;31m"
  case green = "\u{001B}[0;32m"
  case yellow = "\u{001B}[0;33m"
  case blue = "\u{001B}[0;34m"
  case magenta = "\u{001B}[0;35m"
  case cyan = "\u{001B}[0;36m"
  case gray = "\u{001B}[0;90m"
  case white = "\u{001B}[0;37m"
  case reset = "\u{001B}[0;0m"
}
