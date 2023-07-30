
const ResizeEvent = Crossterm.Event{Crossterm.ResizeEvent}
const KeyEvent = Crossterm.Event{Crossterm.KeyEvent}
const MouseEvent = Crossterm.Event{Crossterm.MouseEvent}

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
view(::Model) = nothing
quit(m::Model) = m.quit

keycode(evt::KeyEvent) = evt.data.code
keycode(_) = ""

keymodifier(evt::KeyEvent) = evt.data.modifiers

keypress(evt::KeyEvent) = evt.data.kind == "Press" ? keycode(evt) : ""
keypress(_) = ""

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
