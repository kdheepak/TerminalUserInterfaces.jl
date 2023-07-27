function tui(f::Function; flags...)
  r = nothing
  try
    tui(true; flags...)
    r = f()
  catch err
    tui(false; flags...)
    throw(err)
  finally
    tui(false; flags...)
  end
  return r
end

function tui(switch = true; log = true, enhance_keyboard = true, mouse = true, flush = true)
  if switch
    log && Logger.initialize()
    Crossterm.cursor(false)
    Crossterm.alternate_screen(true)
    Crossterm.raw_mode(true)
    Crossterm.clear()
    mouse && Crossterm.mouse_capture(true)
    enhance_keyboard && Crossterm.enhance_keyboard(true)
  else
    enhance_keyboard && Crossterm.enhance_keyboard(false)
    mouse && Crossterm.mouse_capture(false)
    Crossterm.clear()
    Crossterm.raw_mode(false)
    Crossterm.alternate_screen(false)
    Crossterm.cursor(true)
    log && Logger.reset()
  end
  flush && Crossterm.flush()
end

update!(m, evt) = nothing
view(m) = []
quit(m) = false

function app(m)
  tui() do
    t = Terminal()
    while !quit(m)
      evt = try_get_event(t)
      update!(m, evt)
      w, h = size(t)
      r = Rect(1, 1, w - 2, h - 2)
      for w in view(m)
        draw(t, w, r)
      end
      flush(t)
    end
  end
end
