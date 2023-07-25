using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
  TUI.tui() do
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

    while true

      w, h = TUI.size(t)

      r = TUI.Rect(x, y, w ÷ 2, h ÷ 2)

      b = TUI.Block(; title = "Bar Chart")
      p = TUI.BarChart(;
        block = b,
        data = [
          ("B1", 1 * count)
          ("B2", 2)
          ("B3", 3 * count)
          ("B4", 4)
          ("B1", 5 * count)
          ("B2", 6)
          ("B3", 7 * count)
          ("B4", 8)
        ],
      )

      TUI.draw(t, p, r)
      TUI.flush(t)

      evt = TUI.get_event(t)

      if TUI.keycode(evt) == "q" && evt.data.kind == "Press"
        break
      elseif TUI.keycode(evt) == "j" && evt.data.kind == "Press"
        count += 1
      elseif TUI.keycode(evt) == "k" && evt.data.kind == "Press"
        count -= 1
      end

      if count < 1
        count = 1
      end

    end
  end
end


main()
