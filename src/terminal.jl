import Base.print

struct Terminal
    buffers::Vector{Buffer}
    current::Ref{UInt8}
    cursor_hidden::Ref{Bool}
    terminal_size::Ref{Rect}
    keyboard_buffer::Vector{Char}
    kind::String
    function Terminal()
        width, height = terminal_size()
        rect = Rect(1, 1, width, height)
        buffers = [Buffer(rect), Buffer(rect)]
        current = 1
        cursor_hidden = false
        t = new(buffers, current, cursor_hidden, rect, Char[], get(ENV, "TERM", ""))
        TERMINAL[] = t
        return t
    end
end

const TERMINAL = Ref{Terminal}()

function flush(t::Terminal)
    previous_buffer = t.buffers[END - t.current[]]
    current_buffer = t.buffers[t.current[]]
    draw(t, previous_buffer, current_buffer)
    update(t)
end

draw(terminal::Terminal, buffer1::Buffer, buffer2::Buffer) = draw(stdout, terminal, buffer1, buffer2)

function draw(io, t::Terminal, buffer1::Buffer, buffer2::Buffer)
    save_cursor()
    b1 = buffer1.content[:]
    b2 = buffer2.content[:]
    # a move cursor requires writing a string of 6 - 8 characters
    # doing styles require writing a string of 5 characters
    # undoing styles require writing a string of 5 characters
    # might as well calculate what we need to write and do it in one shot
    # for every character in the diff we need to write 16 - 18 additional characters if we use a diff based algorithm
    # optimize for the case if changes are minimal, moving the cursor is more efficient
    if count(==(0), b1 .== b2) <= length(b2) ÷ 20
        R, C = size(buffer2.content)
        for r = 1:R, c = 1:C
            if buffer1.content[r, c] != buffer2.content[r, c]
                move_cursor(r, c)
                cell = buffer2.content[r, c]
                print(io, cell.style, cell.char, inv(cell.style))
            end
        end
    else
        move_cursor(1, 1)
        iob = IOBuffer()
        for cell in permutedims(buffer2.content)[:]
            print(iob, cell.style, cell.char, inv(cell.style))
        end
        print(io, String(take!(iob)))
    end
    restore_cursor()
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
        clear_screen()
        move_cursor_home()
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
