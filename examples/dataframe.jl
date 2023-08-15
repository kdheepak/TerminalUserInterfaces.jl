using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using DataFrames
using PalmerPenguins
using Tables

@kwdef mutable struct Model <: TUI.Model
  table = DataFrame(PalmerPenguins.load())
  quit = false
end

function TUI.view(m::Model)
  columnnames = Tables.columnnames(Tables.columns(m.table))
  N = length(columnnames)
  header = TUI.Row(; data = [TUI.Datum(; content = string(col)) for col in columnnames])
  rows = map(Tables.rows(m.table)) do row
    TUI.Row(; data = [TUI.Datum(; content = string(item)) for item in row])
  end
  widths = [TUI.Percent(100 ÷ N) for _ in 1:N]
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

