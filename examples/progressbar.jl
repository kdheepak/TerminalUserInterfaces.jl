using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using REPL
using InteractiveUtils

@kwdef mutable struct Model <: TUI.Model
  quit = false
  counter = 1
  max_count = 1000
end

function TUI.view(m::Model)
  b = TUI.Block(; border = TUI.BorderAll)
  pg = TUI.ProgressBar(;
    block = b,
    ratio = m.counter / m.max_count,
    crayon = TUI.Crayon(; foreground = :black, background = :white),
    inv_crayon = TUI.Crayon(; foreground = :white, background = :black),
  )
  pg
end

function TUI.update!(m::Model, ::Nothing)
  m.counter += 1
  if m.counter >= m.max_count
    m.quit = true
  end
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keypress(evt) == "q"
    m.quit = true
  end
end

function main(max_count)
  TUI.app(Model(; max_count))
end

main(100)
