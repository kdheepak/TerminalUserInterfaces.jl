"""
Render Trait for widget
"""
function render(widget, area::Rect, buffer::Buffer) end

Base.@kwdef struct Word
  text::String
  style::Crayon = Crayon()
end
