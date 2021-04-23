class Frame {
  private(set) var fn: CompiledFunction
  private(set) var basePointer: Int
  var ip = -1
  var instructions: Instructions { fn.instructions }

  init(fn: CompiledFunction, basePointer: Int) {
    self.fn = fn
    self.basePointer = basePointer
  }
}
