import Base.print

"""
Terminal
"""
struct Terminal
    buffers::Vector{Buffer}
    current::Ref{UInt8}
    cursor_hidden::Ref{Bool}
    terminal_size::Ref{Rect}
    keyboard_buffer::Vector{Char}
    stdout_channel::Channel{String}
    stdin_channel::Channel{Char}
    kind::String
    wait::Float64
    ispaused::Ref{Bool}
    isclosed::Ref{Bool}
    function Terminal(stdout_io=stdout, stdin_io=stdin)
        (; x, y) = Crossterm.size()
        rect = Rect(1, 1, x, y)
        buffers = [Buffer(rect), Buffer(rect)]
        current = 1
        cursor_hidden = false
        stdout_channel = Channel{String}(Inf)
        stdin_channel = Channel{Char}(Inf)
        ispaused = Ref{Bool}(false)
        isclosed = Ref{Bool}(false)
        stdout_task = @async while !isclosed[]
            if ispaused[] == true
                sleep(0.01)
                continue
            end
            print(stdout_io, take!(stdout_channel))
        end
        stdin_task = @async begin
            Base.start_reading(stdin)
            while !isclosed[]
                if !ispaused[] && bytesavailable(stdin) > 0
                    c = Char(read(stdin_io, 1)[])
                    put!(stdin_channel, c)
                else
                    sleep(0.01)
                end
            end
        end
        t = new(buffers, current, cursor_hidden, rect, Char[], stdout_channel, stdin_channel, get(ENV, "TERM", ""), 1 / 1000, ispaused, isclosed)
        TERMINAL[] = t
        return t
    end
end

function close(t::Terminal)
    t.isclosed[] = true
    t.ispaused[] = true
end

"""
Get key press
"""
function get_event(t)
    return if isready(t.stdin_channel)
        take!(t.stdin_channel)
    else
        nothing
    end
end

function update_channel(t, args...)
    for arg in args
        update_channel(t, string(arg))
    end
end
update_channel(t, arg) = update_channel(t, string(arg))
update_channel(t, arg::String) = put!(t.stdout_channel, arg)

const TERMINAL = Ref{Terminal}()

"""
Flush terminal contents
"""
function flush(t::Terminal, diff=true)
    previous_buffer = t.buffers[END-t.current[]]
    current_buffer = t.buffers[t.current[]]
    if diff
        draw(t, previous_buffer, current_buffer)
    else
        draw(t, current_buffer)
    end
    while isready(t.stdout_channel)
        sleep(1e-6)
    end
    update(t)
end

"""
Move cursor
"""
move_cursor(t::Terminal, row, col) = Crossterm.to(; x=col, y=row)
"""
Move cursor up
"""
move_cursor_up(t::Terminal, row=1) = Crossterm.up(row)
"""
Move cursor down
"""
move_cursor_down(t::Terminal, row=1) = Crossterm.down(row)
"""
Move cursor right
"""
move_cursor_right(t::Terminal, col=1) = Crossterm.right(col)
"""
Move cursor left
"""
move_cursor_left(t::Terminal, col=1) = Crossterm.left(col)
"""
Move cursor home
"""
move_cursor_home(t::Terminal) = Crossterm.to(; x=0, y=0)

"""
Clear screen
"""
clear_screen(t::Terminal) = Crossterm.clear()
"""
Clear screen from cursor up onwards
"""
clear_screen_from_cursor_up(t::Terminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_UP)
"""
Clear screen from cursor down onwards
"""
clear_screen_from_cursor_down(t::Terminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_DOWN)

"""
Clear line
"""
clear_line(t::Terminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)
"""
Clear line from cursor right onwards
"""
clear_line_from_cursor_right(t::Terminal) = Crossterm.clear(Crossterm.ClearType.UNTIL_NEW_LINE)
"""
Clear line from cursor left onwards
"""
clear_line_from_cursor_left(t::Terminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)

"""
Hide cursor
"""
hide_cursor(t::Terminal) = Crossterm.hide()
"""
Show cursor
"""
show_cursor(t::Terminal) = Crossterm.show()

"""
Save cursor
"""
save_cursor(t::Terminal) = Crossterm.save()
"""
Restore cursor
"""
restore_cursor(t::Terminal) = Crossterm.restore()

"""
Change cursor to default
"""
change_cursor_to_default(t::Terminal) = Crossterm.style(Crossterm.Style.DEFAULT_USER_SHAPE)

"""
Change cursor to blinking block
"""
change_cursor_to_blinking_block(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_BLOCK)

"""
Change cursor to steady block
"""
change_cursor_to_steady_block(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_BLOCK)
"""
Change cursor to blinking underline
"""
change_cursor_to_blinking_underline(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_UNDER_SCORE)
"""
Change cursor to steady underline
"""
change_cursor_to_steady_underline(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_UNDER_SCORE)
"""
Change cursor to blinking ibeam
"""
change_cursor_to_blinking_ibeam(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_BAR)
"""
Change cursor to steady ibeam
"""
change_cursor_to_steady_ibeam(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_BAR)

"""
Alternate screen TUI mode
"""
tui_mode(t::Terminal) = Crossterm.alternate_screen(true)
"""
Default mode
"""
default_mode(t::Terminal) = Crossterm.alternate_screen(false)

"""
Get current buffer
"""
current_buffer(t::Terminal)::Buffer = t.buffers[t.current[]]
current_buffer()::Buffer = current_buffer(TERMINAL[])

"""
Reset terminal
"""
reset(t::Terminal, buffer::Int) = reset(t.buffers[buffer])

const END = 2 + 1

"""
Update terminal
"""
function update(t::Terminal)
    reset(t.buffers[END-t.current[]])
    t.current[] = END - t.current[]
    (x, y) = Crossterm.size()
    if t.terminal_size[].width != x || t.terminal_size[].height != y
        resize(t, x, y)
        clear_screen(t)
        move_cursor_home(t)
        # TODO: we need to redraw here.
    end
end

"""
Draw terminal
"""
function draw(t::Terminal, buffer::Buffer)
    save_cursor(t)
    move_cursor_home(t)
    iob = IOBuffer()
    for cell in permutedims(buffer.content)[:]
        print(iob, cell.style, cell.char, inv(cell.style))
    end
    update_channel(t, String(take!(iob)))
    restore_cursor(t)
    while isready(t.stdout_channel)
        sleep(1e-6)
    end
    update(t)
end

"""
Draw terminal
"""
function draw(t::Terminal, buffer1::Buffer, buffer2::Buffer)
    save_cursor(t)
    b1 = buffer1.content[:]
    b2 = buffer2.content[:]
    move_cursor_home(t)
    R, C = size(buffer2.content)
    for r = 1:R, c = 1:C
        if buffer1.content[r, c] != buffer2.content[r, c]
            move_cursor(t, r, c)
            cell = buffer2.content[r, c]
            update_channel(t, cell.style, cell.char, inv(cell.style))
        end
    end
    restore_cursor(t)
end

"""
Resize terminal
"""
function resize(t::Terminal, w::Int, h::Int)
    rect = Rect(1, 1, w, h)
    t.terminal_size[] = rect
    t.buffers[1] = Buffer(rect)
    t.buffers[2] = Buffer(rect)
end

"""
Locate cursor
"""
function locate_cursor(t::Terminal)
    ucs = Char[]
    while length(t.keyboard_buffer) > 0
        push!(ucs, popfirst!(t.keyboard_buffer))
    end
    location = UInt8[]
    with_raw_mode() do
        print(stdout, LOCATECURSOR)
        Base.flush(stdout)
        total_read = 0
        now = time()
        c = 0x00
        bell = UInt8(BELL)
        channel = Channel(1)
        t = @async begin
            while c != UInt8('R')
                c = read(stdin, 1)[]
                push!(location, c)
                total_read += 1
            end
        end
        while c != UInt8('R') && time() - now < CONTROL_SEQUENCE_TIMEOUT
            sleep(1e-3)
        end
        if !istaskdone(t)
            t.exception = InterruptException()
        end
    end
    row, col = split(String(Char.(location)[3:end-1]), ";")
    return parse(Int, row), parse(Int, col)
end
