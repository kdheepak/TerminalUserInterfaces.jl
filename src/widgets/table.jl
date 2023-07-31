@kwdef struct Row
  cells::Vector{Cell}
  height::Int
  style::Crayon = Crayon()
  bottom_margin::Int = 0
end

total_height(row::Row) = row.height + row.bottom_margin


struct TableState
  offset::Int
  selected::Union{Int,Nothing}
end

@kwdef struct Table
  rows::Vector{Row}
  widths::Vector{Constraint}
  state::TableState
  block::Union{Nothing,Block} = nothing
  style::Crayon = Crayon()
  column_spacing::Int = 0
  header::Union{Row,Nothing} = nothing
  highlight_symbol::Union{String,Nothing} = nothing
  highlight_style::Crayon = Crayon()
end

