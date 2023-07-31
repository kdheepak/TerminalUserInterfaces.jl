using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  count = 1
  quit = false
end

function TUI.view(m::Model)
  cells = [TUI.Cell(; content = "Hello"), TUI.Cell(; content = "World")]
  rows = [TUI.Row(; cells), TUI.Row(; cells), TUI.Row(; cells)]
  widths = [TUI.Percent(50), TUI.Percent(50)]
  TUI.Table(; rows, widths)
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keypress(evt) == "q"
    m.quit = true
  end
end

function main()
  TUI.app(Model())
end

main()
