const MAX_AREA = typemax(Int)

struct Margin
    vertical::Int
    horizontal::Int
end

struct Rect
    x::Int
    y::Int
    width::Int
    height::Int
end

function Rect(x, y, aspect_ratio::Rational)
    h = √(max_area / aspect_ratio)
    w = h * aspect_ratio
    return Rect(x, y, w, h)
end

Rect() = Rect(1, 1, 1, 1)

function Rect(rect::Rect, margin::Margin)
    if rect.width < 2 * margin.horizontal || rect.height < 2 * margin.vertical
        return Rect()
    else
        return Rect(
            rect.x + margin.horizontal,
            rect.y + margin.vertical,
            rect.width - 2 * margin.horizontal,
            rect.height - 2 * margin.vertical,
        )
    end
end

area(rect::Rect) = rect.width * rect.height

left(rect::Rect) = rect.x

right(rect::Rect) = rect.x + rect.width

top(rect::Rect) = rect.y

bottom(rect::Rect) = rect.y + rect.height

width(rect::Rect) = rect.width

height(rect::Rect) = rect.height

function inner(rect::Rect; padding_x::Int, padding_y::Int)

    x = left(rect) + padding_x
    y = top(rect) + padding_y
    w = width(rect) - padding_x * 2
    h = height(rect) - padding_y * 2

    return Rect(x, y, w, h)
end

intersects(rect1::Rect, rect2::Rect) = rect1.x < rect2.x + rect2.width && rect1.x + rect1.width > rect2.x && rect1.y < rect2.y + rect2.height && rect1.y + rect1.height > rect2.y

function union(rect1::Rect, rect2::Rect)
    x1 = min(rect1.x, rect2.x)
    y1 = min(rect1.y, rect2.y)
    x2 = max(rect1.x + rect1.width, rect2.x + rect2.width)
    y2 = max(rect1.y + rect1.height, rect2.y + rect2.height)
    return Rect(
        x1,
        y1,
        x2 - x1,
        y2 - y1,
    )
end

function intersection(rect1::Rect, rect2::Rect)
    x1 = max(rect1.x, rect2.x)
    y1 = max(rect1.y, rect2.y)
    x2 = min(rect1.x + rect1.width, rect2.x + rect2.width)
    y2 = min(rect1.y + rect1.height, rect2.y + rect2.height)
    Rect(
        x1,
        y1,
        x2 - x1,
        y2 - y1,
    )
end
