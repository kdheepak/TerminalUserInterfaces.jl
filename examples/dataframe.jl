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
    TUI.next(m.table)
  elseif TUI.keypress(evt) == "k"
    TUI.previous(m.table)
  end
end

function main()
  TUI.app(Model(); wait = 1)
end

main()

