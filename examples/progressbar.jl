using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using REPL
using InteractiveUtils

function main(max_count)
  TUI.tui() do

    y, x = 1, 1

    counter = 1
    t = TUI.Terminal()

    for _ in 1:max_count

      w, h = TUI.size()

      r = TUI.Rect(x, y + 1, w, 2)

      b = TUI.Block(; border = TUI.BorderAll)
      pg = TUI.ProgressBar(b, counter / max_count)

      TUI.draw(t, pg, r)
      TUI.flush(t)

      counter += 1
      sleep(0.00001)

    end
  end

end

main(100)
