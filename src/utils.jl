function tui(f::Function)
  r = nothing
  try
    tui(true)
    r = f()
  catch err
    tui(false)
    throw(err)
  finally
    tui(false)
  end
  return r
end

function tui(switch = true)
  if switch
    Crossterm.cursor(false)
    Crossterm.alternate_screen(true)
    Crossterm.raw_mode(true)
    Crossterm.clear()
  else
    Crossterm.clear()
    Crossterm.raw_mode(false)
    Crossterm.alternate_screen(false)
    Crossterm.cursor(true)
  end
  Crossterm.flush()
end
