# Rect

struct Margin
  vertical::Int
  horizontal::Int
end

struct Rect
  x::Int
  y::Int
  width::Int
  height::Int
end

Rect() = Rect(1, 1, 1, 1)

function Rect(rect::Rect, margin::Margin)
  if rect.width < 2 * margin.horizontal || rect.height < 2 * margin.vertical
    return Rect()
  else
    return Rect(
      rect.x + margin.horizontal,
      rect.y + margin.vertical,
      rect.width - 2 * margin.horizontal,
      rect.height - 2 * margin.vertical,
    )
  end
end

area(rect::Rect) = rect.width * rect.height

left(rect::Rect) = rect.x

right(rect::Rect) = rect.x + rect.width

top(rect::Rect) = rect.y

bottom(rect::Rect) = rect.y + rect.height

width(rect::Rect) = rect.width

height(rect::Rect) = rect.height

function inner(rect::Rect; padding_x::Int, padding_y::Int)
  x = left(rect) + padding_x
  y = top(rect) + padding_y
  w = width(rect) - padding_x * 2
  h = height(rect) - padding_y * 2
  Rect(x, y, w, h)
end

intersects(rect1::Rect, rect2::Rect) =
  rect1.x < rect2.x + rect2.width &&
  rect1.x + rect1.width > rect2.x &&
  rect1.y < rect2.y + rect2.height &&
  rect1.y + rect1.height > rect2.y

function union(rect1::Rect, rect2::Rect)
  x1 = min(rect1.x, rect2.x)
  y1 = min(rect1.y, rect2.y)
  x2 = max(rect1.x + rect1.width, rect2.x + rect2.width)
  y2 = max(rect1.y + rect1.height, rect2.y + rect2.height)
  Rect(x1, y1, x2 - x1, y2 - y1)
end

function intersection(rect1::Rect, rect2::Rect)
  x1 = max(rect1.x, rect2.x)
  y1 = max(rect1.y, rect2.y)
  x2 = min(rect1.x + rect1.width, rect2.x + rect2.width)
  y2 = min(rect1.y + rect1.height, rect2.y + rect2.height)
  Rect(x1, y1, x2 - x1, y2 - y1)
end

# Layout

# Define abstract type Constraint to unify different types of constraints
abstract type Constraint end

# Min constraint to set a minimum value for sizing
struct Min <: Constraint
  value::Int
end

# Max constraint to set a maximum value for sizing
struct Max <: Constraint
  value::Int
end

# Auto constraint to set remaining size
struct Auto <: Constraint
  value::Int
end

# Fixed constraint to set a fixed size
struct Fixed <: Constraint
  value::Int
end

# Horizontal layout to group constraints for horizontal orientation
@kwdef struct Horizontal
  constraints::Vector{Constraint}
end

# Vertical layout to group constraints for vertical orientation
@kwdef struct Vertical
  constraints::Vector{Constraint}
end


function split(layout::Union{Horizontal,Vertical}, area::Rect)
  orientation = layout isa Horizontal ? :horizontal : :vertical
  total_space = orientation == :horizontal ? width(area) : height(area)
  num_constraints = length(layout.constraints)
  model = JuMP.Model(GLPK.Optimizer)
  @variable(model, 0 <= x[1:num_constraints] <= total_space)
  @variable(model, diffs[1:num_constraints, 1:num_constraints] >= 0) # Differences between all pairs of x's
  # Constraints to calculate differences
  for i in 1:num_constraints
    for j in i+1:num_constraints
      @constraint(model, diffs[i, j] >= x[i] - x[j])
      @constraint(model, diffs[i, j] >= x[j] - x[i])
    end
  end
  # Handle Min and Max constraints
  for (i, c) in enumerate(layout.constraints)
    if c isa Min
      @constraint(model, x[i] >= c.value)
    elseif c isa Max
      @constraint(model, x[i] <= c.value)
    elseif c isa Fixed
      @constraint(model, x[i] == c.value)
    end
  end
  # Total space constraint
  @constraint(model, sum(x) == total_space)
  @objective(model, Min, sum(diffs))
  optimize!(model)

  final_sizes = round.(Int, value.(x))
  rects = []
  current_x, current_y = area.x, area.y
  for size in final_sizes
    if isa(layout, Horizontal)
      push!(rects, Rect(current_x, area.y, size, area.height))
      current_x += size
    else
      push!(rects, Rect(area.x, current_y, area.width, size))
      current_y += size
    end
  end
  rects
end

@testset "layout-rects" begin
  constraints = [Fixed(50), Fixed(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Fixed(50), Auto(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Fixed(25), Fixed(25), Fixed(25), Fixed(25)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 25
  @test width(r2) == 25
  @test width(r3) == 25
  @test width(r4) == 25

  constraints = [Min(5), Min(5)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Min(5), Min(10)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Min(5), Min(10), Min(15), Min(20)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 25
  @test width(r2) == 25
  @test width(r3) == 25
  @test width(r4) == 25

  constraints = [Min(5), Auto(50), Min(15), Min(15)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 25
  @test width(r2) == 25
  @test width(r3) == 25
  @test width(r4) == 25

  constraints = [Auto(5), Auto(50), Max(8), Max(15)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 38
  @test width(r2) == 38
  @test width(r3) == 8
  @test width(r4) == 15

  constraints = [Min(5), Fixed(20), Min(15)]
  r1, r2, r3 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 40
  @test width(r2) == 20
  @test width(r3) == 40

  constraints = [Max(95), Fixed(20), Max(85)]
  r1, r2, r3 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 40
  @test width(r2) == 20
  @test width(r3) == 40

  constraints = [Max(5), Min(5)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 5
  @test width(r2) == 95

  constraints = [Min(5), Max(5)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 95
  @test width(r2) == 5

  constraints = [Max(75), Max(75)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Max(75), Max(60)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Max(100), Max(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Max(100), Max(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50
end
