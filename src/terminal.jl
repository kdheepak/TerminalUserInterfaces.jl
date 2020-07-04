import Base.print

struct Terminal
    buffers::Vector{Buffer}
    current::Ref{UInt8}
    cursor_hidden::Ref{Bool}
    terminal_size::Ref{Rect}
    keyboard_buffer::Vector{Char}
    stdout_channel::Channel{String}
    kind::String
    wait::Float64
    function Terminal(io = stdout)
        width, height = terminal_size()
        rect = Rect(1, 1, width, height)
        buffers = [Buffer(rect), Buffer(rect)]
        current = 1
        cursor_hidden = false
        stdout_channel = Channel{String}(Inf)
        _job = @async while true
            print(io, take!(stdout_channel))
        end
        t = new(buffers, current, cursor_hidden, rect, Char[], stdout_channel, get(ENV, "TERM", ""), 1 / 1000)
        TERMINAL[] = t
        return t
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
        sleep(0.00001)
    end
    update(t)
end

function move_cursor(t::Terminal, row, col)
    update_channel(t, Terminals.CSI, INDICES[row], ';', INDICES[col], 'H')
end
save_cursor(t::Terminal) = update_channel(t, SAVECURSOR)
restore_cursor(t::Terminal) = update_channel(t, RESTORECURSOR)
clear_screen(t::Terminal) = update_channel(t, CLEARSCREEN)
move_cursor_home(t::Terminal) = update_channel(t, HOMEPOSITION)

function draw(t::Terminal, buffer1::Buffer, buffer2::Buffer)
    save_cursor(t)
    b1 = buffer1.content[:]
    b2 = buffer2.content[:]
    move_cursor(t, 1, 1)
    iob = IOBuffer()
    for cell in permutedims(buffer2.content)[:]
        print(iob, cell.style, cell.char, inv(cell.style))
    end
    update_channel(t, String(take!(iob)))
    restore_cursor(t)
end

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
