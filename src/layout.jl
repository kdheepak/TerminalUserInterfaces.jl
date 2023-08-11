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

# Auto constraint to set remaining size
struct Auto <: Constraint
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
  variables = [
    (; x = Variable("x_$i"), y = Variable("y_$i"), w = Variable("w_$i"), h = Variable("h_$i")) for
    (i, _) in enumerate(layout.constraints)
  ]
  s = Solver()
  for (i, c) in enumerate(layout.constraints)
    add_constraint(s, variables[i].x >= area.x)
    add_constraint(s, variables[i].y >= area.y)
    add_constraint(s, variables[i].w <= area.width)
    add_constraint(s, variables[i].h <= area.height)
    if c isa Auto
      if orientation == :horizontal
        add_constraint(s, @constraint variables[i].w == c.value strength = KiwiConstraintSolver.STRONG)
      else
        add_constraint(s, @constraint variables[i].h == c.value strength = KiwiConstraintSolver.STRONG)
      end
    elseif c isa Percent
      if orientation == :horizontal
        add_constraint(
          s,
          @constraint variables[i].w == (c.value * width(area) ÷ 100) strength = KiwiConstraintSolver.MEDIUM
        )
      else
        add_constraint(
          s,
          @constraint variables[i].h == (c.value * height(area) ÷ 100) strength = KiwiConstraintSolver.MEDIUM
        )
      end
    elseif c isa Fixed
      if orientation == :horizontal
        add_constraint(s, variables[i].w == c.value)
      else
        add_constraint(s, variables[i].h == c.value)
      end
    elseif c isa Min
      if orientation == :horizontal
        add_constraint(s, variables[i].w >= c.value)
      else
        add_constraint(s, variables[i].h >= c.value)
      end
    elseif c isa Max
      if orientation == :horizontal
        add_constraint(s, variables[i].w <= c.value)
      else
        add_constraint(s, variables[i].h <= c.value)
      end
    end
  end
  for (i, c) in enumerate(layout.constraints)
    if i == 1
      continue
    end
    if orientation == :horizontal
      add_constraint(
        s,
        @constraint variables[i].x == variables[i-1].x + variables[i-1].w + 1 strength = KiwiConstraintSolver.MEDIUM
      )
    else
      add_constraint(
        s,
        @constraint variables[i].y == variables[i-1].y + variables[i-1].h + 1 strength = KiwiConstraintSolver.MEDIUM
      )
    end
  end
  if orientation == :horizontal
    add_constraint(s, sum(variables[i].w for (i, c) in enumerate(layout.constraints)) == width(area))
  else
    add_constraint(s, sum(variables[i].h for (i, c) in enumerate(layout.constraints)) == height(area))
  end
  for (i, c1) in enumerate(layout.constraints), (j, c2) in enumerate(layout.constraints)
    if j <= i
      continue
    end
    if orientation == :horizontal
      add_constraint(s, @constraint variables[i].w == variables[j].w strength = KiwiConstraintSolver.WEAK)
    else
      add_constraint(s, @constraint variables[i].h == variables[j].h strength = KiwiConstraintSolver.WEAK)
    end
  end
  update_variables(s)
  rects = [Rect(round(v.x.value), round(v.y.value), round(v.w.value), round(v.h.value)) for v in variables]
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
  @test width(r1) == 17
  @test width(r2) == 50
  @test width(r3) == 17
  @test width(r4) == 17

  constraints = [Auto(5), Auto(50), Max(8), Max(15)]
  r1, r2, r3, r4 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 27
  @test width(r2) == 50
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

  constraints = [Percent(75), Min(50)]
  r1, r2 = split(Horizontal(constraints), Rect(0, 0, 100, 1))
  @test width(Rect(1, 1, 100, 1)) == 100
  @test width(r1) == 50
  @test width(r2) == 50
end
