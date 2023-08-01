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
  @info "###### STARTING RENDER #######"
  set(buf, area, table.style)
  table_area = table.block === nothing ? area : inner(render(table.block, area, buf))

  has_selection = !isnothing(table.state.selected)
  columns_widths = get_columns_widths(table, table_area.width)
  highlight_symbol = table.highlight_symbol === nothing ? "" : table.highlight_symbol
  current_height = 0
  rows_height = table_area.height

  # Draw header
  if !isnothing(table.header)
    header = table.header
    max_header_height = min(table_area.height, total_height(header))
    set(
      buf,
      Rect(left(table_area), top(table_area), width(table_area), min(height(table_area), height(header))),
      header.style,
    )
    col = left(table_area)
    col += has_selection ? min(width(highlight_symbol), width(table_area)) : 0
    for (width, cell) in zip(columns_widths, header.cells)
      set(buf, Rect(col, top(table_area), width, max_header_height), cell)
      col += width + table.column_spacing
    end
    current_height += max_header_height
    rows_height = rows_height - max_header_height
  end

  # Draw rows
  if isempty(table.rows)
    return
  end

  @info (; columns_widths)
  start, stop = get_row_bounds(table, rows_height)
  @info (; start, stop)
  table.state.offset = start
  for (i, table_row) in enumerate(table.rows[start+1:stop])

    row, col = (top(table_area) + current_height, left(table_area))
    current_height += total_height(table_row)
    @info (; row, col, current_height)
    table_row_area = Rect(col, row, table_area.width, table_row.height)
    set(buf, table_row_area, table_row.style)
    is_selected = table.state.selected === i
    table_row_start_col = if has_selection
      # TODO: implement highlight row
      col
    else
      col
    end
    col = table_row_start_col
    for (width, cell) in zip(columns_widths, table_row.cells)
      set(buf, Rect(col, row, width, table_row.height), cell)
      col += width + table.column_spacing
    end
    if is_selected
      set(buf, table_row_area, table.highlight_style)
    end
  end
end

