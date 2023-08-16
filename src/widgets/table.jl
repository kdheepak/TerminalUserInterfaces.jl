@kwdef struct Datum
  content::String = ""
  style::Crayon = Crayon()
end

@kwdef struct Row
  data::Vector{Datum}
  height::Int = 1
  bottom_margin::Int = 0
end

total_height(row::Row) = row.height + row.bottom_margin

@kwdef mutable struct TableState
  offset::Int = 1
  selected::Union{Int,Nothing} = nothing
end

@kwdef mutable struct Table
  rows::Vector{Row}
  widths::Vector{Constraint}
  state::TableState = TableState()
  block::Union{Nothing,Block} = Block()
  style::Crayon = Crayon()
  column_spacing::Int = 0
  column_widths::Vector{Int} = []
  header::Union{Row,Nothing} = nothing
  highlight_symbol::Union{String,Nothing} = nothing
  highlight_style::Crayon = Crayon()
end


function Table(table)
  columnnames = Tables.columnnames(Tables.columns(table))
  N = length(columnnames)
  header = Row(; data = [Datum(; content = string(col)) for col in columnnames], height = 2)
  rows = map(Tables.rows(table)) do row
    Row(; data = [Datum(; content = string(item)) for item in row])
  end
  widths = [Percent(100 ÷ N) for _ in 1:N]
  Table(; rows, widths, header)
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
    if height + item.height >= max_height
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
  @debug "Calculate widths"
  if length(table.column_widths) == 0
    column_widths = get_columns_widths(table, width(area))
    table.column_widths = column_widths
  else
    column_widths = table.column_widths
  end
  header_height = isnothing(table.header) ? 0 : (table.header.height)
  @debug "Calculate start_row stop_row"
  start_row, stop_row = get_row_bounds(table, height(area) - (header_height + 1))

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
    render_row(table.header, x, y, column_widths, buf)
    y += total_height(table.header)
  end

  # Render rows within start and stop bounds
  @debug "Before rows" start_row stop_row
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
  for (i, datum) in enumerate(row.data)
    # Highlight if row is selected and highlight symbol is provided
    if is_selected && !isnothing(highlight_symbol)
      set(buf, x_offset, y, highlight_symbol)
      x_offset += width(highlight_symbol)
    end
    set(buf, x_offset, y, datum.content, datum.style)
    x_offset += column_widths[i]
  end
end
