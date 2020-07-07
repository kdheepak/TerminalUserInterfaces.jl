import Base.print

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
    function Terminal(stdout_io = stdout, stdin_io = stdin)
        width, height = terminal_size()
        rect = Rect(1, 1, width, height)
        buffers = [Buffer(rect), Buffer(rect)]
        current = 1
        cursor_hidden = false
        stdout_channel = Channel{String}(Inf)
        stdin_channel = Channel{Char}(Inf)
        stdout_task = @async while true
            print(stdout_io, take!(stdout_channel))
        end
        stdin_task = @async while true
            c = Char(read(stdin_io, 1)[])
            put!(stdin_channel, c)
        end
        t = new(buffers, current, cursor_hidden, rect, Char[], stdout_channel, stdin_channel, get(ENV, "TERM", ""), 1 / 1000)
        TERMINAL[] = t
        return t
    end
end

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

function flush(t::Terminal)
    previous_buffer = t.buffers[END - t.current[]]
    current_buffer = t.buffers[t.current[]]
    draw(t, previous_buffer, current_buffer)
    while isready(t.stdout_channel)
        sleep(1e-6)
    end
    update(t)
end

move_cursor(t::Terminal, row, col) = update_channel(t, Terminals.CSI, INDICES[row], ';', INDICES[col], 'H')
move_cursor_up(t::Terminal, row = 1) = update_channel(t, Terminals.CSI, INDICES[row], 'A')
move_cursor_down(t::Terminal, row = 1) = update_channel(t, Terminals.CSI, INDICES[row], 'B')
move_cursor_right(t::Terminal, col = 1) = update_channel(t, Terminals.CSI, INDICES[col], 'C')
move_cursor_left(t::Terminal, col = 1) = update_channel(t, Terminals.CSI, INDICES[col], 'D')
move_cursor_home(t::Terminal) = update_channel(t, HOMEPOSITION)

clear_screen(t::Terminal) = update_channel(t, CLEARSCREEN)
clear_screen_from_cursor_up(t::Terminal) = update_channel(t, CLEARBELOWCURSOR)
clear_screen_from_cursor_down(t::Terminal) = update_channel(t, CLEARABOVECURSOR)

clear_line(t::Terminal) = update_channel(t, CLEARLINE)
clear_line_from_cursor_right(t::Terminal) = update_channel(t, CLEARAFTERCURSOR)
clear_line_from_cursor_left(t::Terminal) = update_channel(t, CLEARBEFORECURSOR)

hide_cursor(t::Terminal) = update_channel(t, HIDECURSOR)
show_cursor(t::Terminal) = update_channel(t, SHOWCURSOR)

save_cursor(t::Terminal) = update_channel(t, SAVECURSOR)
restore_cursor(t::Terminal) = update_channel(t, RESTORECURSOR)

change_cursor_to_blinking_block(t::Terminal) = update_channel(t, CURSORBLINKINGBLOCK)
change_cursor_to_steady_block(t::Terminal) = update_channel(t, CURSORSTEADYBLOCK)
change_cursor_to_blinking_underline(t::Terminal) = update_channel(t, CURSORBLINKINGUNDERLINE)
change_cursor_to_steady_underline(t::Terminal) = update_channel(t, CURSORSTEADYUNDERLINE)
change_cursor_to_blinking_ibeam(t::Terminal) = update_channel(t, CURSORBLINKINGIBEAM)
change_cursor_to_steady_ibeam(t::Terminal) = update_channel(t, CURSORSTEADYIBEAM)

reset(t::Terminal) = update_channel(t, RESET)

tui_mode(t::Terminal) = update_channel(t, TUIMODE)
default_mode(t::Terminal) = update_channel(t, DEFAULTMODE)

current_buffer(t::Terminal)::Buffer = t.buffers[t.current[]]
current_buffer()::Buffer = current_buffer(TERMINAL[])

reset(t::Terminal, buffer::Int) = reset(t.buffers[buffer])

function update(t::Terminal)
    reset(t.buffers[END - t.current[]])
    t.current[] = END - t.current[]
    w, h = terminal_size()
    if t.terminal_size[].width != w || t.terminal_size[].height != h
        resize(t, w, h)
        clear_screen(t)
        move_cursor_home(t)
        # TODO: we need to redraw here.
    end
end

function draw(t::Terminal, buffer1::Buffer, buffer2::Buffer)
    save_cursor(t)
    b1 = buffer1.content[:]
    b2 = buffer2.content[:]
    move_cursor_home(t)
    iob = IOBuffer()
    for cell in permutedims(buffer2.content)[:]
        print(iob, cell.style, cell.char, inv(cell.style))
    end
    update_channel(t, String(take!(iob)))
    restore_cursor(t)
end

function resize(t::Terminal, w::Int, h::Int)
    rect = Rect(1, 1, w, h)
    t.terminal_size[] = rect
    t.buffers[1] = Buffer(rect)
    t.buffers[2] = Buffer(rect)
end

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
