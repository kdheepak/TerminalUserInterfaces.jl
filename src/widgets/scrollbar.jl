abstract type ScrollDirection end
struct Forward <: ScrollDirection end
struct Backward <: ScrollDirection end

mutable struct ScrollbarState
  position::UInt16
  content_length::UInt16
  viewport_content_length::UInt16
end

function position(state::ScrollbarState, position::UInt16)
  state.position = position
  return state
end

function content_length(state::ScrollbarState, content_length::UInt16)
  state.content_length = content_length
  return state
end

function viewport_content_length(state::ScrollbarState, viewport_content_length::UInt16)
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

@kwdef mutable struct Scrollbar
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

function Scrollbar(orientation::ScrollbarOrientation)
  return Scrollbar(orientation, Crayon(), "", Crayon(), "", "", Crayon(), "", Crayon())
end

