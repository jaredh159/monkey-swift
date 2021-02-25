extension String {
  var red: String {
    return "\u{001B}[0;31m" + self + "\u{001B}[0;0m"
  }
  var green: String {
    return "\u{001B}[0;32m" + self + "\u{001B}[0;0m"
  }
}
