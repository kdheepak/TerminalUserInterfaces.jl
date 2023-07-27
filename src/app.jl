init!(m, t) = m.quit = false
update!(m, evt) = update!(m)
update!(m) = @info "No update"
views(m) = [view(m)]
view(m) = nothing
quit(m) = m.quit

function app(m; fps = 30)
  tui() do
    t = Terminal()
    w, h = size(t)
    @info w, h
    init!(m, t)
    while !quit(m)
      evt = try_get_event(t; wait = 1 / fps)
      update!(m, evt)
      w, h = size(t)
      r = Rect(1, 1, w, h)
      for w in views(m)
        render(t, w, r)
      end
      flush(t)
    end
  end
end
