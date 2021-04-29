class Frame {
  private(set) var closure: Closure
  private(set) var basePointer: Int
  var ip = -1
  var instructions: Instructions { closure.fn.instructions }

  init(closure: Closure, basePointer: Int) {
    self.closure = closure
    self.basePointer = basePointer
  }
}
