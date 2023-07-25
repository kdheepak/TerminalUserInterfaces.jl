using Markdown

Base.@kwdef struct MarkdownBlock
  block::Block
  text::Markdown.MD
end

function draw(d::MarkdownBlock, area::Rect, buf::Buffer)
  draw(d.block, area, buf)
  text_area = inner(d.block, area)

  title_area = Rect(left(area), top(area), width(area), height(area) ÷ 5)
  # Assume first block is always the header
  draw(d.text.content[1], title_area, buf)

  body_area = Rect(left(area), bottom(title_area), width(area), height(area) - height(title_area))
  body_area = Rect(body_area, Margin(5, 5))
  items = d.text.content[2:end]
  inner_area = Rect(
    left(body_area),
    top(body_area) - height(body_area) ÷ length(items),
    width(body_area),
    height(body_area) ÷ length(items),
  )
  for (i, c) in enumerate(d.text.content[2:end])
    inner_area = Rect(left(inner_area), bottom(inner_area), width(inner_area), height(inner_area))
    draw(c, inner_area, buf)
  end
end

function draw(h::Markdown.Header, area::Rect, buf::Buffer)
  b = Block(; border_type = BorderTypeLight)
  draw(b, area, buf)

  title = h.text[1]

  row = top(area) + height(area) ÷ 2
  col = width(area) ÷ 2 - (length(title) ÷ 2)
  set(buf, col, row, title, Crayon(; bold = true))
end

function draw(l::Markdown.List, area::Rect, buf::Buffer)

  _s = String[]
  for item in l.items
    iob = IOBuffer()
    print(iob, item[1])
    push!(_s, String(take!(iob)))
  end
  for (i, item) in enumerate(l.items)
    item_area = Rect(
      left(area) + maximum(length.(_s)) ÷ 2,
      top(area) + (i - 1) * (height(area) ÷ length(l.items)),
      width(area),
      height(area) ÷ length(l.items),
    )
    row = top(item_area)
    col = left(item_area)
    set(buf, col, row, " ● ", Crayon(; bold = true, foreground = :red))
    inner_area = Rect(item_area, Margin(0, 5))
    draw(item[1], inner_area, buf)
  end

end

function draw(p::Markdown.Paragraph, area::Rect, buf::Buffer)

  row = top(area)
  col = left(area)
  for c in p.content
    if typeof(c) == String
      l = length(c)
      set(buf, col, row, c)
      col += l
    elseif typeof(c) == Markdown.Bold
      l = length(c.text[1])
      set(buf, col, row, c.text[1], Crayon(; bold = true))
      col += l
    elseif typeof(c) == Markdown.Italic
      l = length(c.text[1])
      set(buf, col, row, c.text[1], Crayon(; italics = true))
      col += l
    elseif typeof(c) == Markdown.Image
      draw(c, area, buf)
    end
  end

end
