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

function tui(switch = true; enhance_keyboard = true, mouse = true, flush = true)
  if switch
    Crossterm.cursor(false)
    Crossterm.alternate_screen(true)
    Crossterm.raw_mode(true)
    Crossterm.clear()
    mouse && Crossterm.mouse_capture(true)
    enhance_keyboard && Crossterm.keyboard_enhancement_flags(true)
  else
    enhance_keyboard && Crossterm.keyboard_enhancement_flags(false)
    mouse && Crossterm.mouse_capture(false)
    Crossterm.clear()
    Crossterm.raw_mode(false)
    Crossterm.alternate_screen(false)
    Crossterm.cursor(true)
  end
  flush && Crossterm.flush()
end
