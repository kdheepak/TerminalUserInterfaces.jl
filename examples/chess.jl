using TerminalUserInterfaces
const TUI = TerminalUserInterfaces
using TUI: set, width , height , left , right , top , bottom , draw , inner

Base.@kwdef struct Chess
    block::Block
    data::Tuple{Tuple{Int, Int}, String}
    cell_width::Int = 4
    cell_height::Int = 4
end

function TUI.draw(grid::Grid, area::Rect, buf::Buffer)
    draw(grid.block, area, buf)
    grid_area = inner(grid.block, area)
    nrows, ncols = size(grid.data)

    ncols * grid.cell_width + 1 > width(grid_area) && return
    nrows * grid.cell_height + 1 > height(grid_area) && return

    for j in 1:ncols
        for i in 1:nrows
            x = left(grid_area) + grid.cell_width * 2 * (j-1) + grid.cell_width
            y = top(grid_area) + grid.cell_height * 1 * (i-1) + grid.cell_height ÷ 2

            set(buf, x, y, "$(grid.data[i, j])")

            for n in -grid.cell_width:grid.cell_width
                set(buf, x + n,  y - grid.cell_height ÷ 2, BOX_DRAWINGS_LIGHT_HORIZONTAL)
                set(buf, x + n,  y + grid.cell_height ÷ 2, BOX_DRAWINGS_LIGHT_HORIZONTAL)
            end

            for n in -grid.cell_height:grid.cell_height
                set(buf, x - grid.cell_width, y + n ÷ 2, BOX_DRAWINGS_LIGHT_VERTICAL)
                set(buf, x + grid.cell_width, y + n ÷ 2, BOX_DRAWINGS_LIGHT_VERTICAL)
            end
        end
    end

    for j in 1:ncols
        for i in 1:nrows
            x = left(grid_area) + grid.cell_width * 2 * (j-1) + grid.cell_width
            y = top(grid_area) + grid.cell_height * 1 * (i-1) + grid.cell_height ÷ 2
            set(buf, x + grid.cell_width, y + grid.cell_height ÷ 2, BOX_DRAWINGS_LIGHT_VERTICAL_AND_HORIZONTAL)
        end
    end

    for j in 1:ncols
        if j == ncols
            continue
        end

        x = left(grid_area) + grid.cell_width * 2 * (j-1) + grid.cell_width

        set(buf, x + grid.cell_width, top(grid_area), BOX_DRAWINGS_LIGHT_DOWN_AND_HORIZONTAL)
        set(buf, x + grid.cell_width, top(grid_area) + nrows * grid.cell_height, BOX_DRAWINGS_LIGHT_UP_AND_HORIZONTAL)

    end

    for i in 1:nrows
        if i == nrows
            continue
        end

        y = top(grid_area) + grid.cell_height * 1 * (i-1) + grid.cell_height ÷ 2

        set(buf, left(grid_area) + ncols * grid.cell_width * 2 , y + grid.cell_height ÷ 2, BOX_DRAWINGS_LIGHT_VERTICAL_AND_LEFT)
        set(buf, left(grid_area), y + grid.cell_height ÷ 2, BOX_DRAWINGS_LIGHT_VERTICAL_AND_RIGHT)

    end

    set(buf, left(grid_area), top(grid_area), BOX_DRAWINGS_LIGHT_DOWN_AND_RIGHT)
    set(buf, left(grid_area), top(grid_area) + nrows * grid.cell_height, BOX_DRAWINGS_LIGHT_UP_AND_RIGHT)

    set(buf, left(grid_area) + ncols * grid.cell_width * 2, top(grid_area), BOX_DRAWINGS_LIGHT_DOWN_AND_LEFT)
    set(buf, left(grid_area) + ncols * grid.cell_width * 2, top(grid_area) + nrows * grid.cell_height, BOX_DRAWINGS_LIGHT_UP_AND_LEFT)
end

function main()
    TUI.initialize()
    y, x = TUI.locate_cursor()

    count = 1
    t = TUI.Terminal()

    TUI.clear_screen()
    TUI.hide_cursor()

    while true

        w, h = TUI.terminal_size()

        p = TUI.Grid(
            block = TUI.Block(title = "Bar Chart"),
            data = [
                    1 2 3
                    4 5 6
                    7 8 9
                   ],
            cell_height = 6,
            cell_width = 6,
        )

        r = TUI.Rect(x, y, w, h)

        TUI.draw(p, r)

        TUI.flush(t)

        c = Char(read(stdin, 1)[])

        if c == 'j'
            count += 1
        elseif c == 'k'
            count -= 1
        elseif c == 'q'
            break
        end

        if count < 1
            count = 1
        end

    end

    TUI.cleanup()

end


main()
