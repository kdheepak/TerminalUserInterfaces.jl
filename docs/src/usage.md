# Usage

To use it in Julia, first add it:

```
(v1.1)> add TerminalUserInterfaces
```

To build a Terminal User Interface (TUI), you'll need a main loop.
`TerminalUserInterfaces.jl` is a library based on the immediate mode rendering concept.
Every iteration of the main loop, the User Interface is "drawn" from scratch.
This means writing out text to the screen every frame.

While this may appear to be a limitation from a performance perspective, in practice it works well with stateful UI.
Also to increase performance, `TerminalUserInterfaces.jl` maintains two buffers and draws only the difference between frames.


```
        START      TUI.draw.(t, w)    END
          *-------*-----*---*----*-----*
                   ^            /
                    \          v
                     * <------*
       TUI.get_event(t)       TUI.flush(t)
```

## Example

```julia
using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
```

### Initialize

To create a TUI, the first thing you need to do is call `initialize`


```julia
TUI.initialize()
```

This function does a few things:

```julia
backup_termios()
tui_mode()
hide_cursor()
enable_raw_mode()
clear_screen()
move_cursor_home()
```

- `backup_termios()`: backups termios settings to recover back to default terminal settings
- `tui_mode()`: starts an alternate buffer
- `hide_cursor()`: makes cursor not visible
- `enable_raw_mode()`: capture key presses as they happen without waiting for the enter key
- `clear_screen()`: clear the screen of all text
- `move_cursor_home()`: moves the cursor to the top left of the terminal window

Every `TUI.initialize()` at beginning of a program must be paired with `TUI.cleanup()` at the end of a program.

```julia
move_cursor_home()
clear_screen()
disable_raw_mode()
show_cursor()
default_mode()
```

After calling `initialize`, we can create the application.
To start, let's create an instance of `Terminal`.

```julia
t = TUI.Terminal()
```

This holds references to the frame buffers and allows us to call helper functions to create a TUI.

### Draw Widgets

Let's look at an example of a `SelectableList` widget.

![](https://user-images.githubusercontent.com/1813121/74565866-15daa600-4f6a-11ea-8d4a-58ec8e7679a1.gif)

```julia
w, _ = TUI.terminal_size()
rect = TUI.Rect(1, 1, w ÷ 4, 20)
widget = TUI.SelectableList(
    TUI.Block(title = "Option Picker"),
    words,
    scroll,
    selection,
)
TUI.draw(t, widget, rect)
```

`TUI.draw(t, widget, rect)` calls `draw(list::SelectableList, area::Rect, buf::Buffer)` which implements how to draw the widget.
The `Buffer` is a `Matrix{Cell}` where `Cell` contains a julia `Char` and information on how to style it.

```julia
struct Cell
    char::Char
    style::Crayons.Crayon
end
```

This is useful to know when implementing your own widgets.

You can draw as many widgets as you want. If widgets are drawn at the same location, they will overwrite the `Cell` characters in the `Buffer`.

Finally, calling `TUI.flush(t)` draws the current frame to the terminal.

```julia
TUI.flush(t)
```

### Getting user input

`TerminalUserInterfaces.jl` sets up `stdout` and `stdin` `Channel`s

Calling `TUI.get_event(t)` reads from the `stdin` `Channel`.

```julia
function get_event(t)
    if isready(t.stdin_channel)
        return take!(t.stdin_channel)
    end
end
```

This function is non-blocking. You can also call `take!(t.stdin_channel)` to block till the user presses a key.

Drawing, taking user input and acting on it and redrawing is what your main loop of the terminal user interface will look like.

### Minimum Working Example

```julia
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
        TUI.Crayon()
    ]

    words = [TUI.Word(word, styles[rand(rng, 1:length(styles))]) for word in words]

    scroll = 1
    selection = 1
    final = ""

    while true

        w, _ = TUI.terminal_size()

        r = TUI.Rect(x, y, w ÷ 4, 20)

        b = TUI.Block(title = "Option Picker")
        p = TUI.SelectableList(
            b,
            words,
            scroll,
            selection,
        )

        TUI.draw(t, p, r)

        TUI.flush(t)

        count += 1

        c = TUI.get_event(t)

        if c == 'j'
            selection += 1
        elseif c == 'k'
            selection -= 1
        elseif c == '\r'
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

    TUI.cleanup()

    println(final)

end

main()
```
