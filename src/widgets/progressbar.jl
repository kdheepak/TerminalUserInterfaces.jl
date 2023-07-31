Base.@kwdef struct ProgressBar
  block::Block
  ratio::Float64 = 0
  crayon::Crayon = Crayon()
  inv_crayon::Union{Nothing,Crayon} = nothing
end

function render(pg::ProgressBar, rect::Rect, buf::Buffer)
  (pg.ratio < 0 || pg.ratio > 1) && error("Got $(pg.ratio). ProgressBar ratio must be in [0, 1].")
  render(pg.block, rect, buf)

  inner_area = inner(pg.block, rect)

  center = height(inner_area) ÷ 2 + top(inner_area)

  inv_crayon = isnothing(pg.inv_crayon) ? inv(pg.crayon) : pg.inv_crayon

  for y in top(inner_area):(bottom(inner_area)-1)
    for x in left(inner_area):right(inner_area)
      if x <= pg.ratio * (right(inner_area) - left(inner_area) + 1)
        set(buf, x, y, pg.crayon)
      else
        set(buf, x, y, inv_crayon)
      end
    end
  end

  label = "$(round(pg.ratio * 100))%"
  middle = Int(round((width(inner_area) - length(label)) / 2 + left(inner_area)))
  set(buf, middle, center, label)

end
