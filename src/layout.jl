# Rect

@kwdef struct Margin
  vertical::Int
  horizontal::Int
end

@kwdef struct Rect
  x::Int = 1
  y::Int = 1
  width::Int = 1
  height::Int = 1
end

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

# Length constraint to set remaining size
struct Length <: Constraint
  value::Int
end

# Percent constraint to set a percent size
struct Percent <: Constraint
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
  variables = [(; start = Variable("start_$i"), stop = Variable("stop_$i")) for (i, _) in enumerate(layout.constraints)]
  total_len = orientation == :horizontal ? width(area) : height(area)
  starting_pos = orientation == :horizontal ? area.x : area.y
  s = Solver()
  for (i, c) in enumerate(layout.constraints)
    if c isa Fixed
      add_constraint(
        s,
        @constraint (variables[i].stop - variables[i].start) == c.value strength = KiwiConstraintSolver.STRONG
      )
    elseif c isa Min
      add_constraint(
        s,
        @constraint (variables[i].stop - variables[i].start) >= c.value strength = KiwiConstraintSolver.STRONG
      )
    elseif c isa Max
      add_constraint(
        s,
        @constraint (variables[i].stop - variables[i].start) <= c.value strength = KiwiConstraintSolver.STRONG
      )
    elseif c isa Length
      add_constraint(
        s,
        @constraint (variables[i].stop - variables[i].start) == c.value strength = KiwiConstraintSolver.STRONG
      )
    elseif c isa Percent
      add_constraint(
        s,
        @constraint (variables[i].stop - variables[i].start) == (c.value * total_len ÷ 100) strength =
          KiwiConstraintSolver.STRONG
      )
    end
  end
  for (i, c) in enumerate(layout.constraints)
    add_constraint(s, variables[i].stop >= variables[i].start)
    if i == 1
      add_constraint(s, variables[i].start == starting_pos)
    else
      add_constraint(s, variables[i].start == variables[i-1].stop)
    end
    if i == length(layout.constraints)
      add_constraint(s, variables[i].stop == starting_pos + total_len)
    end
  end
  add_constraint(
    s,
    sum((variables[i].stop - variables[i].start) for (i, c) in enumerate(layout.constraints)) == total_len,
  )
  for (i, _) in enumerate(layout.constraints), (j, _) in enumerate(layout.constraints)
    if j <= i
      continue
    end
    add_constraint(
      s,
      @constraint (variables[i].stop - variables[i].start) == (variables[j].stop - variables[j].start) strength =
        KiwiConstraintSolver.WEAK
    )
  end
  update_variables(s)
  rects = if orientation == :horizontal
    [Rect(round(v.start.value), top(area), round(v.stop.value - v.start.value), height(area)) for v in variables]
  else
    [Rect(left(area), round(v.start.value), width(area), round(v.stop.value - v.start.value)) for v in variables]
  end
  rects
end

@testset "layout-rects-gaps" begin
  target = Rect(; x = 2, y = 2, width = 10, height = 10)
  constraints = [Percent(10), Max(5), Min(1)]
  r1, r2, r3 = split(Horizontal(constraints), target)
  @test r1 == Rect(; x = 2, y = 2, width = 1, height = 10)
  @test r2 == Rect(; x = 3, y = 2, width = 4, height = 10)
  @test r3 == Rect(; x = 8, y = 2, width = 4, height = 10)
end

@testset "layout-rects-fixed" begin
  constraints = [Fixed(50), Fixed(50)]
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
end

@testset "layout-rects-min" begin
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
end

@testset "layout-rects-mixed" begin
  constraints = [Fixed(50), Length(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50

  constraints = [Min(5), Length(50), Min(15), Min(15)]
  r = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  r1, r2, r3, r4 = r
  @test_broken sum(width.(r)) == 100
  @test width(Rect(0, 0, 100, 1)) == 100
  @test width(r1) == 17
  @test width(r2) == 50
  @test width(r3) == 17
  @test width(r4) == 17

  constraints = [Length(5), Length(50), Max(8), Max(15)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 17
  @test width(r2) == 50
  @test width(r3) == 17
  @test width(r4) == 17

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

  constraints = [Percent(75), Min(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50
end
