abstract type ScrollDirection end
struct Forward <: ScrollDirection end
struct Backward <: ScrollDirection end

@kwdef mutable struct ScrollbarState
  position::Int
  content_length::Int
  viewport_content_length::Int = 0
end

function position(state::ScrollbarState, position)
  state.position = position
  return state
end

function content_length(state::ScrollbarState, content_length)
  state.content_length = content_length
  return state
end

function viewport_content_length(state::ScrollbarState, viewport_content_length)
  state.viewport_content_length = viewport_content_length
  return state
end

function prev(state::ScrollbarState)
  state.position = state.position - 1
end

function next(state::ScrollbarState)
  state.position = clamp(state.position + 1, 0, state.content_length - 1)
end

function first(state::ScrollbarState)
  state.position = 0
end

function last(state::ScrollbarState)
  state.position = state.content_length - 1
end

function scroll(state::ScrollbarState, direction::ScrollDirection)
  if direction isa Forward
    next(state)
  elseif direction isa Backward
    prev(state)
  end
end

abstract type ScrollbarOrientation end
struct VerticalRight <: ScrollbarOrientation end
struct VerticalLeft <: ScrollbarOrientation end
struct HorizontalBottom <: ScrollbarOrientation end
struct HorizontalTop <: ScrollbarOrientation end

@kwdef struct Scrollbar
  state::ScrollbarState
  orientation::ScrollbarOrientation = VerticalRight()
  thumb_style::Crayon = Crayon()
  thumb_symbol::String = "█"
  track_style::Crayon = Crayon()
  track_symbol::String = "║"
  begin_symbol::Union{String,Nothing} = "▲"
  begin_style::Crayon = Crayon()
  end_symbol::Union{String,Nothing} = "▼"
  end_style::Crayon = Crayon()
end

function is_vertical(scrollbar::Scrollbar)::Bool
  orientation = scrollbar.orientation
  return orientation isa VerticalRight || orientation isa VerticalLeft
end

function get_track_area(scrollbar::Scrollbar, area::Rect)
  if scrollbar.begin_symbol !== nothing
    if is_vertical(scrollbar)
      area = Rect(area.x, area.y + 1, area.width, area.height - 1)
    else
      area = Rect(area.x + 1, area.y, area.width - 1, area.height)
    end
  end
  if scrollbar.end_symbol !== nothing
    if is_vertical(scrollbar)
      return Rect(area.x, area.y, area.width, area.height - 1)
    else
      return Rect(area.x, area.y, area.width - 1, area.height)
    end
  else
    return area
  end
end

function should_not_render(scrollbar::Scrollbar, track_start, track_end, content_length)
  return track_end - track_start == 0 || content_length == 0
end

function get_track_start_end(scrollbar::Scrollbar, area::Rect)
  orientation = scrollbar.orientation
  if orientation isa VerticalRight
    return (top(area), bottom(area), right(area) - 1)
  elseif orientation isa VerticalLeft
    return (top(area), bottom(area), left(area))
  elseif orientation isa HorizontalBottom
    return (left(area), right(area), bottom(area) - 1)
  elseif orientation isa HorizontalTop
    return (left(area), right(area), top(area))
  end
end

function get_thumb_start_end(scrollbar::Scrollbar, track_start_end)
  state = scrollbar.state
  track_start, track_end = track_start_end

  viewport_content_length = if state.viewport_content_length == 0
    track_end - track_start
  else
    state.viewport_content_length
  end

  scroll_position_ratio = min(state.position / state.content_length, 1.0)

  thumb_size = max(round(((viewport_content_length / state.content_length) * (track_end - track_start))), 1)

  track_size = (track_end - track_start) - thumb_size

  thumb_start = track_start + round(scroll_position_ratio * track_size)

  thumb_end = thumb_start + thumb_size

  return (thumb_start, thumb_end)
end


function render(scrollbar::Scrollbar, area::Rect, buffer::Buffer)
  state = scrollbar.state
  # Extract the area where the track will be rendered
  area = get_track_area(scrollbar, area)
  track_start, track_end, track_axis = get_track_start_end(scrollbar, area)

  if should_not_render(scrollbar, track_start, track_end, state.content_length)
    return
  end

  thumb_start, thumb_end = get_thumb_start_end(scrollbar, (track_start, track_end))

  for i in track_start:track_end-1
    if i >= thumb_start && i < thumb_end
      style = scrollbar.thumb_style
      symbol = scrollbar.thumb_symbol
    else
      style = scrollbar.track_style
      symbol = scrollbar.track_symbol
    end

    if is_vertical(scrollbar)
      set(buffer, track_axis, i, symbol, style)
    else
      set(buffer, i, track_axis, symbol, style)
    end
  end

  if scrollbar.begin_symbol !== nothing
    s = scrollbar.begin_symbol
    if is_vertical(scrollbar)
      set(buffer, track_axis, track_start - 1, s, scrollbar.begin_style)
    else
      set(buffer, track_start - 1, track_axis, s, scrollbar.begin_style)
    end
  end

  if scrollbar.end_symbol !== nothing
    s = scrollbar.end_symbol
    if is_vertical(scrollbar)
      set(buffer, track_axis, track_end, s, scrollbar.end_style)
    else
      set(buffer, track_end, track_axis, s, scrollbar.end_style)
    end
  end
end

