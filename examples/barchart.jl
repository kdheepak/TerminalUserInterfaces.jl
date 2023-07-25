using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
  TUI.tui() do
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

    TUI.Crossterm.clear()
    TUI.Crossterm.hide()

    while true

      s = TUI.Crossterm.size()

      r = TUI.Rect(x, y, s.x ÷ 2, s.y ÷ 2)

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

      if evt.tag == TUI.Crossterm.EventTag.KEY && evt.data.code == "q"
        break
      elseif evt.tag == TUI.Crossterm.EventTag.KEY && evt.data.code == "j"
        count += 1
      elseif evt.tag == TUI.Crossterm.EventTag.KEY && evt.data.code == "k"
        count -= 1
      end

      if count < 1
        count = 1
      end

    end
  end
end


main()
