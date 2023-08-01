@kwdef struct Layout
  widgets::Vector
  constraints::Vector{<:Constraint}
  orientation::Symbol = :vertical
end

function render(layout::Layout, area::Rect, buf::Buffer)
  if length(layout.widgets) != length(layout.constraints)
    throw(ArgumentError("Number of widgets must match the number of constraints"))
  end
  orientation = layout.orientation

  rects = if orientation == :vertical
    split(Vertical(; constraints = layout.constraints), area)
  else
    split(Horizontal(; constraints = layout.constraints), area)
  end

  for (widget, rect) in zip(layout.widgets, rects)
    render(widget, rect, buf)
  end
end
