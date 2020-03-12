

struct Key
    val::Symbol
end

function poll_events(io)

    inputs = Char[]

    @async begin

    while bytesavailable(io) != 0
        push!(inputs, Char(read(io, 1)[]))
    end

    end
    # if inputs[1] == '\x11' # CTRL + Q
    #     break
    # elseif String(inputs) == "\e[A" # ⬆
    #     move_square_up(c)
    # elseif String(inputs) == "\e[B" # ⬇
    #     move_square_down(c)
    # elseif String(inputs) == "\e[C" # ➡
    #     move_square_right(c)
    # elseif String(inputs) == "\e[D" # ⬅
    #     move_square_left(c)
    # end

end
