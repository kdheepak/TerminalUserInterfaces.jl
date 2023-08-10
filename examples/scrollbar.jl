using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

const WORDS = repeat("The Quick Brown Fox Jumps Over The Lazy Dog. ", 120)

@kwdef mutable struct Model <: TUI.Model
  rng = MersenneTwister()
  styles = [
    TUI.Crayon(; bold = true)
    TUI.Crayon(; italics = true)
    TUI.Crayon(; foreground = :red)
    TUI.Crayon(; foreground = :blue)
    TUI.Crayon(; foreground = :green)
    TUI.Crayon(; bold = true, foreground = :red)
    TUI.Crayon(; bold = true, foreground = :blue)
    TUI.Crayon(; bold = true, foreground = :green)
    TUI.Crayon(; italics = true, foreground = :red)
    TUI.Crayon(; italics = true, foreground = :blue)
    TUI.Crayon(; italics = true, foreground = :green)
    TUI.Crayon()
  ]
  words = [TUI.Word(word, styles[rand(rng, 1:length(styles))]) for word in split(WORDS)]
  number_of_lines = Ref{Int}(0)
  scroll = 1
  quit = false
end

function TUI.views(m::Model)
  b = TUI.Block(; title = "Scrollbar example")
  p = TUI.Paragraph(b, m.words, m.scroll, m.number_of_lines)
  s = TUI.Scrollbar(; state = TUI.ScrollbarState(m.scroll, p.number_of_lines[], 0))
  [p, s]
end

function TUI.update!(m::Model, evt::TUI.KeyEvent)
  if TUI.keycode(evt) == "j" && evt.data.kind == "Press"
    m.scroll += 1
  elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
    m.scroll -= 1
  elseif TUI.keycode(evt) == "q" && evt.data.kind == "Press"
    m.quit = true
  elseif TUI.keycode(evt) == "c" && "Ctrl" ∈ TUI.keymodifier(evt) && evt.data.kind == "Press"
    # keyboard interrupt
    m.quit = true
  end
  if m.scroll < 1
    m.scroll = 1
  end
  if m.scroll > m.number_of_lines[]
    m.scroll = m.number_of_lines[]
  end
end


function main()
  TUI.app(Model())
end


main()
