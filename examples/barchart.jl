using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  count = 1
  quit = false
end

function TUI.view(m::Model)
  b = TUI.Block(; title = "Bar Chart")
  TUI.BarChart(;
    block = b,
    data = [
      ("B1", 1 * m.count)
      ("B2", 2)
      ("B3", 3 * m.count)
      ("B4", 4)
      ("B1", 5 * m.count)
      ("B2", 6)
      ("B3", 7 * m.count)
      ("B4", 8)
    ],
  )
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keypress(evt) == "q"
    m.quit = true
  elseif TUI.keypress(evt) == "j"
    m.count += 1
  elseif TUI.keypress(evt) == "k"
    m.count -= 1
  end

  if m.count < 1
    m.count = 1
  end
end

function main()
  TUI.app(Model())
end

main()
