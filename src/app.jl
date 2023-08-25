
"""
```julia
import TerminalUserInterface as TUI

struct TUIModel <: TUI.Model
  quit::Bool
end
```
"""
abstract type Model end

terminal(::Model) = TERMINAL[]
init!(m::Model, ::TerminalBackend) = m.quit = false
update!(m::Model, ::Crossterm.Event) = update!(m)
update!(::Model, ::Nothing) = nothing
update!(::Model) = @info "No update"
function update!(m::Model, evt::ResizeEvent)
  update!(terminal(m), evt)
end
views(m::Model) = [view(m)]
view(::Model) = @debug "No view found for model"
should_quit(m::Model) = m.quit
render(m::Model, r::Rect, buf::Buffer) =
  for w in views(m)
    @debug "rendering $(typeof(w))"
    render(w, r, buf)
  end

function app(m; wait = 1 / 30)
  tui() do
    @debug "Creating terminal"
    t = Terminal(; wait)
    init!(m, t)
    while !should_quit(m)
      @debug "Getting event"
      evt = try_get_event(t)
      !isnothing(evt) && @debug "Got event" event = evt
      @debug "Updating model"
      update!(m, evt)
      @debug "Rendering model"
      render(t, m)
      @debug "Drawing model"
      draw(t)
    end
    @debug "End"
  end
end
