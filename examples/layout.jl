using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model
  quit = false
end

function TUI.init!(m, _)
  m.quit = false
end

function TUI.update!(m::Model, evt)
  if TUI.keypress(evt) == "q"
    m.quit = true
  end
end

function TUI.view(m::Model)
  block1 = TUI.Block(; title = "Block 1")
  block2 = TUI.Block(; title = "Block 2")
  block3 = TUI.Block(; title = "Block 3")

  horizontal1 = TUI.Horizontal(; widgets = [block1, block2, block3], constraints = [TUI.Percentage(30), TUI.Min(5), TUI.Percentage(30)])
  horizontal2 = TUI.Horizontal(; widgets = [block1, block2, block3], constraints = [TUI.Min(5), TUI.Percentage(30), TUI.Percentage(30)])
  TUI.Vertical(; widgets = [horizontal1, horizontal2], constraints = [TUI.Percentage(50), TUI.Percentage(50)])
end

function main()
  m = Model()
  TUI.app(m)
end

main()

