using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
  TUI.tui() do
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

    words = repeat("The Quick Brown Fox Jumps Over The Lazy Dog. ", 60)

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

    words = [TUI.Word(word, styles[rand(rng, 1:length(styles))]) for word in split(words)]

    scroll = 1

    while true

      r = TUI.Rect(x, y, TUI.Crossterm.size().x, 35)

      b = TUI.Block(; title = "Paragraph example")
      p = TUI.Paragraph(b, words, scroll)

      TUI.draw(t, p, r)

      TUI.flush(t)

      count += 1

      evt = TUI.get_event(t)

      if TUI.keycode(evt) == "j" && evt.data.kind == "Press"
        scroll += 1
      elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
        scroll -= 1
      elseif TUI.keycode(evt) == "q" && evt.data.kind == "Press"
        break
      elseif TUI.keycode(evt) == "c" && "Ctrl" ∈ TUI.keymodifier(evt) && evt.data.kind == "Press"
        # keyboard interrupt
        break
      end
      if scroll < 1
        scroll = 1
      end
      if scroll > p.number_of_lines[]
        scroll = p.number_of_lines[]
      end

    end
  end
end


main()
