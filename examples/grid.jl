using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
  TUI.tui() do
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

    while true

      p = TUI.Grid(; block = TUI.Block(; title = "Grid"), data = [
        1 2 3
        4 5 6
        7 8 9
      ])

      w, h = TUI.size(t)
      r = TUI.Rect(x, y, w, h)

      TUI.draw(t, p, r)
      TUI.flush(t)

      evt = TUI.get_event(t)

      if TUI.keycode(evt) == "j" && evt.data.kind == "Press"
        count += 1
      elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
        count -= 1
      elseif TUI.keycode(evt) == "q" && evt.data.kind == "Press"
        break
      end

      if count < 1
        count = 1
      end

    end
  end
end


main()
