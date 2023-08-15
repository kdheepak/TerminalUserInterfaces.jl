using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

@kwdef mutable struct Model <: TUI.Model
  count = 1
  quit = false
end

function TUI.view(m::Model)
  data = [TUI.Datum(; content = "Hello"), TUI.Datum(; content = "World"), TUI.Datum(; content = "FSFDS")]
  header = TUI.Row(;
    data = [
      TUI.Datum(; content = "Column1", style = TUI.Crayon(; foreground = :black, background = :white)),
      TUI.Datum(; content = "Column2", style = TUI.Crayon(; foreground = :black, background = :white)),
      TUI.Datum(; content = "Column3", style = TUI.Crayon(; foreground = :black, background = :white)),
    ],
  )
  rows = [
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
    TUI.Row(; data),
  ]
  widths = [TUI.Percent(33), TUI.Percent(33), TUI.Percent(33)]
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
