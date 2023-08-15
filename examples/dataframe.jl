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
  TUI.Table(m.table)
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

