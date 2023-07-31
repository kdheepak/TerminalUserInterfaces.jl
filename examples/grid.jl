using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  count = 1
  quit = false
end

function TUI.init!(m, _)
  m.quit = false
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keypress(evt) == "j"
    m.count += 1
  elseif TUI.keypress(evt) == "k"
    m.count -= 1
  elseif TUI.keypress(evt) == "q"
    m.quit = true
  end

  if m.count < 1
    m.count = 1
  end
end

function TUI.view(m::Model)
  TUI.Grid(; block = TUI.Block(; title = "Grid"), data = [
    1 2 3
    4 5 6
    7 8 9
  ])
end

function main()
  m = Model()
  TUI.app(m)
end

main()
