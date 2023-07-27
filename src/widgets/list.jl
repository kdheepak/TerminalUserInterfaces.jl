struct List
  block::Block
  items::Vector{Word}
  scroll::Int
end

function render(list::List, area::Rect, buf::Buffer)
  render(list.block, area, buf)
  list_area = inner(list.block, area)

  if width(list_area) < 1 || height(list_area) < 1
    return
  end

  x, y = left(list_area), top(list_area)

  for (i, item) in enumerate(list.items)
    if i < list.scroll || i - list.scroll > height(list_area)
      continue
    end
    set(buf, x + 1, y, '*')
    set(buf, x + 3, y, item.text, item.style)
    y += 1
  end
end

struct SelectableList
  block::Block
  items::Vector{Word}
  scroll::Int
  selected::Int
end

function render(list::SelectableList, area::Rect, buf::Buffer)
  list_area = inner(list.block, area)

  render(list.block, area, buf)
  list_area = inner(list.block, area)

  if width(list_area) < 1 || height(list_area) < 1
    return
  end

  x, y = left(list_area), top(list_area)

  for (i, item) in enumerate(list.items)
    if i < list.scroll || i - list.scroll > height(list_area)
      continue
    end
    if i == list.selected
      set(buf, x + 1, y, '>')
      set(buf, x + 3, y, item.text, item.style * Crayon(; bold = true, italics = true))
    else
      set(buf, x + 1, y, '*')
      set(buf, x + 3, y, item.text, item.style)
    end
    y += 1
  end
end
