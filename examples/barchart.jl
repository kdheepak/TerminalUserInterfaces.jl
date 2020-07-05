using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using Random

function main()
    TUI.initialize()
    y, x = 1, 1

    count = 1
    t = TUI.Terminal()

    # TUI.enableRawMode()
    TUI.clear_screen()
    TUI.hide_cursor()

    while true

        w, h = TUI.terminal_size()

        r = TUI.Rect(x, y, w ÷ 2, h ÷ 2)

        b = TUI.Block(title = "Bar Chart")
        p = TUI.BarChart(
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

        c = TUI.get_event(t)

        if c == 'j'
            count += 1
        elseif c == 'k'
            count -= 1
        elseif c == 'q'
            break
        end

        if count < 1
            count = 1
        end

    end

    TUI.cleanup()

end


main()
