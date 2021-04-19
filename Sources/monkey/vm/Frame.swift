class Frame {
  var fn: CompiledFunction
  var ip = -1
  var instructions: Instructions { fn.instructions }

  init(fn: CompiledFunction) {
    self.fn = fn
  }
}
