const BAR = (
  " ",
  LOWER_ONE_EIGHTH_BLOCK,
  LOWER_ONE_QUARTER_BLOCK,
  LOWER_THREE_EIGHTHS_BLOCK,
  LOWER_HALF_BLOCK,
  LOWER_FIVE_EIGHTHS_BLOCK,
  LOWER_THREE_QUARTERS_BLOCK,
  LOWER_SEVEN_EIGHTHS_BLOCK,
  FULL_BLOCK,
)

Base.@kwdef struct BarChart
  block::Block
  data::Vector{Tuple{String,Int}}
  width::Int = 0
  gap::Int = 0
end

function render(bar_chart::BarChart, area::Rect, buf::Buffer)
  render(bar_chart.block, area, buf)
  @info "" area
  chart_area = inner(bar_chart.block, area)
  @info "" chart_area

  w = bar_chart.width
  gap = bar_chart.gap
  if w == 0 || gap == 0
    w = (width(chart_area) ÷ length(bar_chart.data)) - 1
    gap = 1
  end

  height(chart_area) < 2 && return

  max_data = maximum([v for (_, v) in bar_chart.data])

  data = [Int(round(d * (height(chart_area) - 1) * 8 / max_data, RoundUp)) for (_, d) in bar_chart.data]

  for j in reverse(top(chart_area):height(chart_area))
    @info "" top(chart_area), j
    for (i, d) in enumerate(data)
      symbol = d > 8 ? BAR[9] : BAR[Int(round(d / 8, RoundUp))+1]
      for x in 1:w
        set(buf, left(chart_area) + (i - 1) * (w + gap) + x, j, symbol)
      end
      if d > 8
        d -= 8
      else
        d = 0
      end
      data[i] = d
    end
  end

  data = [Int(round(d * (height(chart_area) - 1) * 8 / max_data, RoundUp)) for (_, d) in bar_chart.data]

  for (i, d) in enumerate(data)
    s = bar_chart.data[i][1]
    if length(s) < w
      set(
        buf,
        left(chart_area) + (i - 1) * (w + gap) + (w ÷ 2) - (length(s) ÷ 2) + 1,
        top(chart_area) + height(chart_area) - d ÷ 8 - 1,
        s,
      )
    end

  end
end
