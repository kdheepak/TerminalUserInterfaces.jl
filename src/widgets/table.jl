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
  block::Union{Nothing,Block} = nothing
  style::Crayon = Crayon()
  column_spacing::Int = 5
  header::Union{Row,Nothing} = nothing
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
  @info (; chunks)
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

  # Calculate column widths and row bounds
  column_widths = get_columns_widths(table, width(area))
  start_row, stop_row = get_row_bounds(table, height(area))

  # Optionally render block around the table
  if !isnothing(table.block)
    render(table.block, area, buf)
  end

  # Create the table area inside the block (if exists) or the full area
  table_area = isnothing(table.block) ? area : inner(table.block, area)

  x, y = left(table_area), top(table_area)

  # Optionally render the header row
  if !isnothing(table.header)
    render_row(table.header, x, y, column_widths, buf)
    y += total_height(table.header)
  end

  # Render rows within start and stop bounds
  for i in start_row+1:stop_row
    row = table.rows[i]
    render_row(row, x, y, column_widths, buf)
    y += total_height(row)
  end
end

# Helper function to render a row
function render_row(row::Row, x::Int, y::Int, column_widths::Vector{Int}, buf::Buffer)
  x_offset = x
  for (i, cell) in enumerate(row.cells)
    # Render cell (you may need to define this part, depending on how you want to display cells)
    # Example:
    set(buf, x_offset, y, cell.content, cell.style)
    x_offset += column_widths[i]
  end
end


