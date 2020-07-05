using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using REPL
using InteractiveUtils

function main(max_count)
    TUI.initialize()

    y, x = 1, 1

    counter = 1
    t = TUI.Terminal()

    ADDITIVE = 1

    for _ in 1:max_count

        w, _ = TUI.terminal_size()

        r = TUI.Rect(x, y + 1, w, 2)

        b = TUI.Block(border = TUI.BorderNone, border_type = TUI.BorderTypeHeavy)
        pg = TUI.ProgressBar(b, counter / max_count)

        TUI.draw(t, pg, r)

        TUI.flush(t)

        counter += 1

    end

    println()

    TUI.cleanup()

end

main(1000)
