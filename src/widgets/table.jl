@kwdef struct Row
  cells::Vector{Cell}
  height::Int = 3
  style::Crayon = Crayon()
  bottom_margin::Int = 0
end

total_height(row::Row) = row.height + row.bottom_margin


@kwdef mutable struct TableState
  offset::Int
  selected::Union{Int,Nothing}
end

@kwdef struct Table
  rows::Vector{Row}
  widths::Vector{Constraint}
  state::TableState = TableState(; offset = 1, selected = nothing)
  block::Union{Nothing,Block} = Block()
  style::Crayon = Crayon()
  column_spacing::Int = 0
  header::Union{Row,Nothing} = nothing
  header_style::Crayon = Crayon()
  highlight_symbol::Union{String,Nothing} = nothing
  highlight_style::Crayon = Crayon()
end

function get_columns_widths(table::Table, max_width::Int)
  constraints = Constraint[]
  for constraint in table.widths
    push!(constraints, constraint)
    push!(constraints, Min(table.column_spacing))
  end
  chunks = split(Horizontal(; constraints), Rect(0, 0, max_width, 1))
  return map(c -> c.width, chunks[1:2:end])
end

function get_row_bounds(table::Table, max_height::Int)
  offset = min(table.state.offset, length(table.rows) - 1)
  start = offset
  stop = offset
  height = 0
  for item in table.rows[start+1:end]
    if height + item.height > max_height
      break
    end
    height += total_height(item)
    stop += 1
  end

  selected = isnothing(table.state.selected) ? 1 : min(table.state.selected, length(table.rows))
  while selected >= stop
    height += total_height(table.rows[stop+1])
    stop += 1
    while height > max_height
      height -= total_height(table.rows[start+1])
      start += 1
    end
  end
  while selected < start
    start -= 1
    height += total_height(table.rows[start+1])
    while height > max_height
      stop -= 1
      height -= total_height(table.rows[stop+1])
    end
  end
  return start, stop
end

function render(table::Table, area::Rect, buf::Buffer)
  # Check if there's space to render
  if width(area) < 1 || height(area) < 1
    return
  end

  # Set initial style
  set(buf, area, table.style)

  # Calculate column widths and row bounds
  column_widths = get_columns_widths(table, width(area))
  start_row, stop_row = get_row_bounds(table, height(area))

  # Optionally render block around the table
  if !isnothing(table.block)
    render(table.block, area, buf)
  end

  # Create the table area inside the block (if exists) or the full area
  table_area = !isnothing(table.block) ? inner(table.block, area) : area

  x, y = left(table_area), top(table_area)

  # Optionally render the header row
  if !isnothing(table.header)
    max_header_height = min(table_area.height, total_height(table.header))
    set(
      buf,
      Rect(;
        x = left(table_area),
        y = top(table_area),
        width = width(table_area),
        height = min(table_area.height, table.header.height),
      ),
      table.header.style,
    )
    render_row(table.header, x, y, column_widths, buf)
    y += total_height(table.header)
  end

  # Render rows within start and stop bounds
  for i in start_row+1:stop_row
    row = table.rows[i]
    is_selected = i == table.state.selected
    render_row(row, x, y, column_widths, buf, is_selected, table.highlight_symbol)
    y += total_height(row)
  end
end

# Helper function to render a row
function render_row(
  row::Row,
  x::Int,
  y::Int,
  column_widths::Vector{Int},
  buf::Buffer,
  is_selected::Bool = false,
  highlight_symbol::Union{Nothing,String} = nothing,
)
  x_offset = x
  for (i, cell) in enumerate(row.cells)
    # Highlight if row is selected and highlight symbol is provided
    if is_selected && !isnothing(highlight_symbol)
      set(buf, x_offset, y, highlight_symbol, cell.style)
      x_offset += width(highlight_symbol)
    end
    render_cell(buf, cell, Rect(; x = x_offset, y = y, width = column_widths[i], height = row.height))
    x_offset += column_widths[i]
  end
  if is_selected
    set(buf, Rect(; x = x, y = y, width = sum(column_widths), height = row.height), table.highlight_style)
  end
end

function render_cell(buf::Buffer, cell::Cell, area::Rect)
  set(buf, area, cell.style)
  set(buf, left(area), top(area), Base.split(cell.content, '\n'))
end

