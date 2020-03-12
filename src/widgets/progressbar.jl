Base.@kwdef struct ProgressBar
    block::Block
    ratio::Float64
    function ProgressBar(block, ratio)
        ( ratio < 0 || ratio > 1 ) && error("Got $ratio. ProgressBar ratio must be in [0, 1].")
        new(block, ratio)
    end
end

function draw(pg::ProgressBar, rect::Rect, buf::Buffer)
    draw(pg.block, rect, buf)

    inner_area = inner(pg.block, rect)

    center = height(inner_area) ÷ 2 + top(inner_area)

    crayon = Crayon(foreground = :white, background = :black)

    for y in top(inner_area):bottom(inner_area)
        for x in left(inner_area):right(inner_area)
            if x <= pg.ratio * (right(inner_area) - left(inner_area) + 1)
                set(buf, x, y, crayon)
            else
                set(buf, x, y, inv(crayon))
            end
        end
    end

    label = "$(round(pg.ratio * 100))%"
    middle = Int(round( (width(inner_area) - length(label)) / 2 + left(inner_area) ))
    set(buf, middle, center, label)

end
