
Base.@kwdef struct Cell
    char::Char
    style::Crayons.Crayon
end

Cell(char) = Cell(char, Crayons.Crayon())

convert(::Type{Cell}, char::Char) = Cell(char)

struct Buffer
    area::Rect
    content::Matrix{Cell}
end

Buffer(rect::Rect) = Buffer(rect, Cell(' '))

function Buffer(rect::Rect, cell::Cell)
    content = Matrix{Cell}(undef, rect.height, rect.width)
    for i in eachindex(content)
        content[i] = deepcopy(cell)
    end
    return Buffer(rect, content)
end

function Buffer(lines::Vector{String})

    height = length(lines)
    width = maximum(length(l) for l in lines)
    buffer = Buffer(
                Rect(
                    1,
                    1,
                    width,
                    height,
                ),
            )
    for (y, line) in enumerate(lines)
        set(buffer, 1, y, line)
    end
    return buffer
end

function set(buffer::Buffer, col::Integer, row::Integer, style::Crayons.Crayon)
    row = min(row, size(buffer.content, 1))
    col = min(col, size(buffer.content, 2))
    buffer.content[row, col] = Cell(buffer.content[row, col].char, style)
end

function set(buffer::Buffer, col::Integer, row::Integer, lines::Vector{T}) where T <: AbstractString
    for line in lines
        set(buffer, col, row, string(line))
        row += 1
    end
end

function set(buffer::Buffer, col::Integer, row::Integer, line::String)
    for (_col, c) in enumerate(line)
        set(buffer, col + _col - 1, row, c)
    end
end

function set(buffer::Buffer, col::Integer, row::Integer, line::String, style::Crayons.Crayon)
    for (_col, c) in enumerate(line)
        set(buffer, col + _col - 1, row, c, style)
    end
end

function set(buffer::Buffer, col::Integer, row::Integer, c::Char)
    set(buffer, col, row, c, buffer.content[row, col].style)
end

function set(buffer::Buffer, col::Integer, row::Integer, c::Char, style::Crayons.Crayon)
    set(buffer, col, row, Cell(c, style))
end

function set(buffer::Buffer, col::Integer, row::Integer, c::Cell)
    row = min(row, size(buffer.content, 1))
    col = min(col, size(buffer.content, 2))
    buffer.content[row, col] = c
end

reset(buffer::Buffer) = fill!(buffer.content, Cell(' '))

function diff(buffer1::Buffer, buffer2::Buffer)
    arr = Tuple{Tuple{Int, Int}, Cell}[]
    R, C = size(buffer1.content)
    for c in 1:C
        for r in 1:R
            if buffer1.content[r, c] != buffer2.content[r, c]
                push!(arr, ((r, c), buffer2.content[r, c]))
            end
        end
    end
    return arr
end


function background(buf::Buffer, rect::Rect, color::Crayons.Crayon)
    for y in top(rect):bottom(rect)
        for x in left(rect):right(rect)
            set(buf, x, y, color);
        end
    end
end

draw(t, widget, r::Rect) = draw(widget, r, current_buffer(t))
