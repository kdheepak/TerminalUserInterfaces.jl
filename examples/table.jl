using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  count = 1
  quit = false
end

function TUI.view(m::Model)
  cells = [
    TUI.Cell(; content = "Hello", style = TUI.Crayon(; foreground = :black, background = :white)),
    TUI.Cell(; content = "World", style = TUI.Crayon(; foreground = :black, background = :white)),
  ]
  header = TUI.Row(;
    cells = [
      TUI.Cell(; content = "Column1", style = TUI.Crayon(; foreground = :black, background = :white)),
      TUI.Cell(; content = "Column2", style = TUI.Crayon(; foreground = :black, background = :white)),
    ],
  )
  rows = [
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
    TUI.Row(; cells),
  ]
  widths = [TUI.Auto(50), TUI.Auto(50)]
  TUI.Table(; rows, widths, header)
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
