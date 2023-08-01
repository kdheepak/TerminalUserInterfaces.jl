abstract type Constraint end

struct Min <: Constraint
  value::Int
end

struct Max <: Constraint
  value::Int
end

struct Percent <: Constraint
  value::Int
end

@kwdef struct Horizontal
  constraints::Vector{Constraint}
end

@kwdef struct Vertical
  constraints::Vector{Constraint}
end

function split(layout::Union{Horizontal,Vertical}, area::Rect)
  orientation = layout isa Horizontal ? :horizontal : :vertical

  start_pos = orientation == :horizontal ? left(area) : top(area)
  total_space = orientation == :horizontal ? width(area) : height(area)

  min_and_max_lengths = Int[0 for _ in layout.constraints]
  percentage_constraints = Int[0 for _ in layout.constraints]
  for (i, constraint) in enumerate(layout.constraints)
    if constraint isa Min
      min_and_max_lengths[i] = constraint.value
    elseif constraint isa Max
      min_and_max_lengths[i] = constraint.value
    elseif constraint isa Percent
      percentage_constraints[i] = constraint.value
    else
      throw(ArgumentError("Invalid constraint"))
    end
  end

  # Calculate the remaining length for percentage constraints
  remaining_length = total_space - sum(min_and_max_lengths)
  for (i, constraint) in enumerate(layout.constraints)
    if constraint isa Percent
      min_and_max_lengths[i] = (percentage_constraints[i] * remaining_length) ÷ 100
    end
  end

  # If there's any Min constraint, distribute the remaining width equally to all Min constraints
  remaining_length = total_space - sum(min_and_max_lengths)
  num_min_constraints = count(c -> c isa Min, layout.constraints)
  if num_min_constraints > 0 && remaining_length > 0
    extra_length_per_min = div(remaining_length, num_min_constraints)
    for (i, constraint) in enumerate(layout.constraints)
      if constraint isa Min
        min_and_max_lengths[i] += extra_length_per_min
      end
    end
  end

  rects = []
  for len in min_and_max_lengths
    rect =
      orientation == :horizontal ? Rect(start_pos, top(area), len - 1, height(area)) :
      Rect(left(area), start_pos, width(area), len - 1)
    push!(rects, rect)
    start_pos += len
  end
  rects
end

@testset "layout-rects" begin
  constraints = [Min(5), Min(5)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(r1) == 49
  @test width(r2) == 49
end

