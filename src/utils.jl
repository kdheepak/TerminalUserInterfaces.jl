function with_raw_mode(f::Function)
    try
        Crossterm.raw_mode(true)
        f()
    finally
        Crossterm.raw_mode(false)
    end
end

function initialize()
    Crossterm.alternate_screen()
    Crossterm.hide()
    Crossterm.raw_mode()
    Crossterm.clear()
end

function cleanup()
    Crossterm.clear()
    Crossterm.raw_mode(false)
    Crossterm.show()
    Crossterm.alternate_screen(false)
end
