struct Border
  val::UInt
end

Base.convert(::Type{Border}, val::Integer) = Border(val)
Base.promote_rule(::Type{Border}, ::Type{Integer}) = Border

const BorderNone = Border(0b0000)
const BorderTop = Border(0b0001)
const BorderRight = Border(0b0010)
const BorderBottom = Border(0b0100)
const BorderLeft = Border(0b1000)
const BorderAll = Border(0b1111)

Base.:&(b1::Border, b2::Border) = Border(b1.val & b2.val)
Base.:&(b1::Integer, b2::Border) = Border(b1 & b2.val)
Base.:&(b1::Border, b2::Integer) = Border(b1.val & b2)

Base.:|(b1::Border, b2::Border) = Border(b1.val | b2.val)
Base.:|(b1::Integer, b2::Border) = Border(b1 | b2.val)
Base.:|(b1::Border, b2::Integer) = Border(b1.val | b2)

Base.:(==)(b1::Border, b2::Border) = ==(b1.val, b2.val)
Base.:(==)(b1::Integer, b2::Border) = ==(b1, b2.val)
Base.:(==)(b1::Border, b2::Integer) = ==(b1.val, b2)

Base.:(<)(b1::Border, b2::Border) = b1.val < b2.val
Base.:(<)(b1::Integer, b2::Border) = b1 < b2.val
Base.:(<)(b1::Border, b2::Integer) = b1.val < b2

struct BorderType{T} end

Base.convert(::Type{BorderType}, val::Symbol) = BorderType{val}()

const BorderTypeLight = BorderType{:LIGHT}()
const BorderTypeHeavy = BorderType{:HEAVY}()
const BorderTypeDouble = BorderType{:DOUBLE}()
const BorderTypeArc = BorderType{:ARC}()

vertical(::BorderType) = BOX_DRAWINGS_LIGHT_VERTICAL
horizontal(::BorderType) = BOX_DRAWINGS_LIGHT_HORIZONTAL
top_left(::BorderType) = BOX_DRAWINGS_LIGHT_DOWN_AND_RIGHT
top_right(::BorderType) = BOX_DRAWINGS_LIGHT_DOWN_AND_LEFT
bottom_left(::BorderType) = BOX_DRAWINGS_LIGHT_UP_AND_RIGHT
bottom_right(::BorderType) = BOX_DRAWINGS_LIGHT_UP_AND_LEFT

vertical(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_VERTICAL
horizontal(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_HORIZONTAL
top_left(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_DOWN_AND_RIGHT
top_right(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_DOWN_AND_LEFT
bottom_left(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_UP_AND_RIGHT
bottom_right(::BorderType{:HEAVY}) = BOX_DRAWINGS_HEAVY_UP_AND_LEFT

vertical(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_VERTICAL
horizontal(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_HORIZONTAL
top_left(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_DOWN_AND_RIGHT
top_right(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_DOWN_AND_LEFT
bottom_left(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_UP_AND_RIGHT
bottom_right(::BorderType{:DOUBLE}) = BOX_DRAWINGS_DOUBLE_UP_AND_LEFT

vertical(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_VERTICAL
horizontal(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_HORIZONTAL
top_left(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_RIGHT
top_right(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_ARC_DOWN_AND_LEFT
bottom_left(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_ARC_UP_AND_RIGHT
bottom_right(::BorderType{:ARC}) = BOX_DRAWINGS_LIGHT_ARC_UP_AND_LEFT

Base.@kwdef struct Block
  title::String = ""
  title_style::Crayon = Crayon()
  border::Border = Border(0b1111)
  border_type::BorderType = BorderTypeLight
  border_style::Crayon = Crayon()
end

function draw(b::Block, area::Rect, buf::Buffer)
  if b.border & BorderLeft > 0
    x = left(area)
    symbol = vertical(b.border_type)
    for y in top(area):bottom(area)
      set(buf, x, y, symbol, b.border_style)
    end
  end
  if b.border & BorderTop > 0
    y = top(area)
    symbol = horizontal(b.border_type)
    for x in left(area):right(area)
      set(buf, x, y, symbol, b.border_style)
    end
  end
  if b.border & BorderRight > 0
    x = right(area)
    symbol = vertical(b.border_type)
    for y in top(area):bottom(area)
      set(buf, x, y, symbol, b.border_style)
    end
  end
  if b.border & BorderBottom > 0
    y = bottom(area)
    symbol = horizontal(b.border_type)
    for x in left(area):right(area)
      set(buf, x, y, symbol, b.border_style)
    end
  end

  if b.border & BorderLeft > 0 && b.border & BorderTop > 0
    set(buf, left(area), top(area), top_left(b.border_type), b.border_style)
  end
  if b.border & BorderRight > 0 && b.border & BorderTop > 0
    set(buf, right(area), top(area), top_right(b.border_type), b.border_style)
  end
  if b.border & BorderLeft > 0 && b.border & BorderBottom > 0
    set(buf, left(area), bottom(area), bottom_left(b.border_type), b.border_style)
  end
  if b.border & BorderRight > 0 && b.border & BorderBottom > 0
    set(buf, right(area), bottom(area), bottom_right(b.border_type), b.border_style)
  end
  X = left(area)
  W = min(width(area), size(buf.content, 2))
  set(buf, X + 2, top(area), b.title, b.title_style)
end


function inner(b::Block, area::Rect)
  if width(area) < 2 || height(area) < 2
    return Rect()
  end

  x = left(area)
  y = top(area)
  w = width(area)
  h = height(area)

  if b.border & BorderLeft > 0
    x += 1
    w -= 1
  end
  if b.border & BorderTop > 0
    y += 1
    h -= 1
  end
  if b.border & BorderRight > 0
    w -= 1
  end
  if b.border & BorderBottom > 0
    h -= 1
  end

  return Rect(x, y, w, h)
end
