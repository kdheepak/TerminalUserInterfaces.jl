using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
  final = TUI.tui() do
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

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

    rng = MersenneTwister()
    styles = [
      # TUI.Crayon(bold = true)
      # TUI.Crayon(italics = true)
      # TUI.Crayon(foreground = :red)
      # TUI.Crayon(foreground = :blue)
      # TUI.Crayon(foreground = :green)
      # TUI.Crayon(bold = true, foreground = :red)
      # TUI.Crayon(bold = true, foreground = :blue)
      # TUI.Crayon(bold = true, foreground = :green)
      # TUI.Crayon(italics = true, foreground = :red)
      # TUI.Crayon(italics = true, foreground = :blue)
      # TUI.Crayon(italics = true, foreground = :green)
      TUI.Crayon(),
    ]

    words = [TUI.Word(word, styles[rand(rng, 1:length(styles))]) for word in words]

    scroll = 1
    selection = 1
    final = ""

    while true

      w, h = TUI.size()

      r = TUI.Rect(x, y, w ÷ 4, 20)

      b = TUI.Block(; title = "Option Picker")
      p = TUI.SelectableList(b, words, scroll, selection)

      TUI.draw(t, p, r)

      TUI.flush(t)

      count += 1

      evt = TUI.get_event(t)

      if TUI.keycode(evt) == "j" && evt.data.kind == "Press"
        selection += 1
      elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
        selection -= 1
      elseif TUI.keycode(evt) == "q" && evt.data.kind == "Press"
        break
      elseif TUI.keycode(evt) == "Enter" && evt.data.kind == "Press"
        final = words[selection].text
        break
      end
      if selection < 1
        selection = 1
      end
      if selection > length(words)
        selection = length(words)
      end

    end
    final
  end

  println(final)
end


main()
