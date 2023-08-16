using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using DataFrames
using PalmerPenguins
using Tables

@kwdef mutable struct Model <: TUI.Model
  table = TUI.Table(DataFrame(PalmerPenguins.load()))
  quit = false
end

function TUI.view(m::Model)
  m.table
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  @info "" evt
  if TUI.keypress(evt) == "q"
    m.quit = true
  elseif TUI.keypress(evt) == "j"
    m.table.state.offset += 1
    m.table.state.offset = min(length(m.table.rows), m.table.state.offset)
    m.table.state.selected = m.table.state.offset
  elseif TUI.keypress(evt) == "k"
    m.table.state.offset -= 1
    m.table.state.offset = max(1, m.table.state.offset)
    m.table.state.selected = m.table.state.offset
  end
end

function main()
  TUI.app(Model(); wait = 0)
end

main()

