using TUI


function main(max_count)
    TUI.initialize()

    y, x = TUI.locate_cursor()

    count = 1
    t = TUI.Terminal()

    ADDITIVE = 1

    for _ in 1:max_count

        w, _ = TUI.terminal_size()

        r = TUI.Rect(x, y + 1, w, 2)

        b = TUI.Block(border = TUI.BorderNone, border_type = TUI.BorderTypeHeavy)
        pg = TUI.ProgressBar(b, count / max_count)

        TUI.draw(pg, r)

        TUI.flush(t)

        count += 1

    end

    println()

    TUI.cleanup()

end


@time main(10000)
