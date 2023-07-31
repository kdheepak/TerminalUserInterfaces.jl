
abstract type Model end

terminal(::Model) = TERMINAL[]
init!(m::Model, ::Terminal) = m.quit = false
update!(m::Model, ::Crossterm.Event) = update!(m)
update!(::Model, ::Nothing) = nothing
update!(::Model) = @info "No update"
function update!(m::Model, evt::ResizeEvent)
  update!(terminal(m), evt)
end
views(m::Model) = [view(m)]
view(::Model) = @debug "No view found for model"
should_quit(m::Model) = m.quit

function app(m; fps = 30)
  tui() do
    @debug "Creating terminal"
    t = Terminal()
    init!(m, t)
    while !should_quit(m)
      @debug "Getting event"
      evt = try_get_event(t; wait = 1 / fps)
      !isnothing(evt) && @debug "Got event" event = evt
      @debug "Updating model"
      update!(m, evt)
      @debug "Rendering model"
      r = area(t)
      for w in views(m)
        @debug "rendering $(typeof(w))"
        render(t, w, r)
      end
      @debug "Drawing model"
      draw(t)
    end
    @debug "End"
  end
end
