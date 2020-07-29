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

    words = repeat("The Quick Brown Fox Jumps Over The Lazy Dog. ", 60)

    rng = MersenneTwister()
    styles = [
        TUI.Crayon(bold = true)
        TUI.Crayon(italics = true)
        TUI.Crayon(foreground = :red)
        TUI.Crayon(foreground = :blue)
        TUI.Crayon(foreground = :green)
        TUI.Crayon(bold = true, foreground = :red)
        TUI.Crayon(bold = true, foreground = :blue)
        TUI.Crayon(bold = true, foreground = :green)
        TUI.Crayon(italics = true, foreground = :red)
        TUI.Crayon(italics = true, foreground = :blue)
        TUI.Crayon(italics = true, foreground = :green)
        TUI.Crayon()
    ]

    words = [TUI.Word(word, styles[rand(rng, 1:length(styles))]) for word in split(words)]

    scroll = 1

    while true

        w, h = TUI.terminal_size()

        r = TUI.Rect(x, y, w, 35)

        b = TUI.Block(title = "Paragraph example")
        p = TUI.Paragraph(
            b,
            words,
            scroll,
        )

        TUI.draw(t, p, r)

        TUI.flush(t, false)

        count += 1

        c = TUI.get_event(t)

        if c == 'j'
            scroll += 1
        elseif c == 'k'
            scroll -= 1
        elseif c == 'q'
            break
        elseif c == '\x03'
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

    TUI.cleanup()

end


main()
