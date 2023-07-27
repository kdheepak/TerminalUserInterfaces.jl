using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random
using Logging

@kwdef mutable struct Model
  words = [
    "Option A"
    "Option B"
    "Option C"
    "Option D"
    "Option E"
    "Option F"
    "Option G"
    "Option H"
    "Option I"
  ]
  selection = 1
  scroll = 1
  quit = false
end

function TUI.update!(m::Model, evt)
  if TUI.keycode(evt) == "j" && evt.data.kind == "Press"
    m.selection += 1
  elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
    m.selection -= 1
  elseif TUI.keycode(evt) == "q" && evt.data.kind == "Press"
    m.quit = true
  elseif TUI.keycode(evt) == "Enter" && evt.data.kind == "Press"
    m.quit = true
  end
  if m.selection < 1
    m.selection = 1
  end
  if m.selection > length(m.words)
    m.selection = length(m.words)
  end
end

function TUI.view(m)
  words = [TUI.Word(word, TUI.Crayon()) for word in m.words]
  block = TUI.Block(; title = "Option Picker")
  [TUI.SelectableList(block, words, m.scroll, m.selection)]
end

TUI.quit(m) = m.quit

function main()
  m = Model()
  TUI.app(m)
  println(m.words[m.selection])
end


main()
