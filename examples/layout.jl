# ┌─Block 1────────────────────┐┌─Block 2─────────────────────────────────────┐┌─Block 3────────────────────┐
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# │                            ││                                             ││                            │
# └────────────────────────────┘└─────────────────────────────────────────────┘└────────────────────────────┘
# ┌─Block 1─────────────────────────────────────┐┌─Block 2────────────────────┐┌─Block 3────────────────────┐
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# │                                             ││                            ││                            │
# └─────────────────────────────────────────────┘└────────────────────────────┘└────────────────────────────┘

using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  quit = false
end

function TUI.init!(m, _)
  m.quit = false
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keypress(evt) == "q"
    m.quit = true
  end
end

function TUI.render(m::Model, r::TUI.Rect, buf::TUI.Buffer)
  block1 = TUI.Block(; title = "Block 1")
  block2 = TUI.Block(; title = "Block 2")
  block3 = TUI.Block(; title = "Block 3")

  v1, v2 = TUI.split(TUI.Vertical(; constraints = [TUI.Percent(50), TUI.Percent(50)]), r)
  h1, h2, h3 = TUI.split(TUI.Horizontal(; constraints = [TUI.Percent(30), TUI.Min(5), TUI.Percent(30)]), v1)
  TUI.render(block1, h1, buf)
  TUI.render(block2, h2, buf)
  TUI.render(block3, h3, buf)

  h1, h2, h3 = TUI.split(TUI.Horizontal(; constraints = [TUI.Min(5), TUI.Percent(30), TUI.Percent(30)]), v2)
  TUI.render(block1, h1, buf)
  TUI.render(block2, h2, buf)
  TUI.render(block3, h3, buf)
end

function main()
  m = Model()
  TUI.app(m)
end

main()

