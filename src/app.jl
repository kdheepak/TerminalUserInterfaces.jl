init!(m, t) = m.quit = false
update!(m, evt) = update!(m)
update!(m) = @info "No update"
function update!(m, evt::Crossterm.Event{Crossterm.ResizeEvent})
  update!(TERMINAL[], evt)
end
views(m) = [view(m)]
view(m) = nothing
quit(m) = m.quit

function app(m; fps = 30)
  tui() do
    @debug "Creating terminal"
    t = Terminal()
    init!(m, t)
    while !quit(m)
      @debug "Getting event"
      evt = try_get_event(t; wait = 1 / fps)
      !isnothing(evt) && @debug "Got event" event = evt
      @debug "Updating model"
      update!(m, evt)
      @debug "Rendering model"
      r = area(t)
      for w in views(m)
        render(t, w, r)
      end
      @debug "Drawing model"
      draw(t)
    end
    @debug "End"
  end
end
