import Base.print
import Dates

abstract type TerminalBackend end

"""
CrosstermTerminal
"""
struct CrosstermTerminal <: TerminalBackend
  buffers::Vector{Buffer}
  current::Ref{UInt8}
  previous::Ref{UInt8}
  cursor_hidden::Ref{Bool}
  terminal_size::Ref{Rect}
  keyboard_buffer::Vector{Char}
  kind::String
  wait::Float64
  function CrosstermTerminal(; wait = 1 / 1000)
    (; w, h) = Crossterm.size()
    rect = Rect(1, 1, w, h)
    buffers = [Buffer(rect), Buffer(rect)]
    current = 1
    previous = 2
    cursor_hidden = false
    t = new(buffers, current, previous, cursor_hidden, rect, Char[], get(ENV, "TERM", ""), wait)
    TERMINAL[] = t
    return t
  end
end

# TODO: come up with better way to expose terminal
const TERMINAL = Ref{CrosstermTerminal}()

# TODO: make terminal function return any backend. Right now there's only one backend - `CrosstermTerminal`
Terminal(; wait = 1 / 1000) = CrosstermTerminal(; wait)

function close(::CrosstermTerminal) end

"""
Get event (nonblocking)

# kwargs

- wait (seconds)
"""
function try_get_event(t::CrosstermTerminal; wait = t.wait)
  if Crossterm.poll(Dates.Nanosecond(round(wait * 1e9)))
    Crossterm.read()
  else
    nothing
  end
end

"""
Get event (blocking)
"""
function get_event(::CrosstermTerminal)
  Crossterm.read()
end

"""
Flush terminal
"""
flush(::CrosstermTerminal) = Crossterm.flush()

function update!(t::CrosstermTerminal, evt) end
function update!(t::CrosstermTerminal, evt::Crossterm.Event{Crossterm.MouseEvent}) end
function update!(t::CrosstermTerminal, evt::Crossterm.Event{Crossterm.KeyEvent}) end
function update!(t::CrosstermTerminal, evt::Crossterm.Event{Crossterm.ResizeEvent})
  (; w, h) = evt.data
  resize(t, w, h)
  clear_screen(t)
  move_cursor_home(t)
  flush(t)
end

const END = 2 + 1

"""
Draw terminal contents
"""
function draw(t::CrosstermTerminal)
  pb = previous_buffer(t)
  cb = current_buffer(t)
  save_cursor(t)
  R, C = Base.size(cb.content)
  for r in 1:R, c in 1:C
    if pb.content[r, c] != cb.content[r, c]
      move_cursor(t, r, c)
      cell = cb.content[r, c]
      put(cell)
    end
  end
  restore_cursor(t)
  Crossterm.foreground(:reset)
  Crossterm.background(:reset)
  Crossterm.underline(:reset)
  Crossterm.style(:reset)
  Crossterm.flush()
  switch_buffers(t)
  reset(current_buffer())
end

function switch_buffers(t)
  t.current[], t.previous[] = t.previous[], t.current[]
end

"""
Move cursor
"""
move_cursor(::CrosstermTerminal, row, col) = Crossterm.to(; x = col - 1, y = row - 1)
"""
Move cursor up
"""
move_cursor_up(::CrosstermTerminal, row = 1) = Crossterm.up(row)
"""
Move cursor down
"""
move_cursor_down(::CrosstermTerminal, row = 1) = Crossterm.down(row)
"""
Move cursor right
"""
move_cursor_right(::CrosstermTerminal, col = 1) = Crossterm.right(col)
"""
Move cursor left
"""
move_cursor_left(::CrosstermTerminal, col = 1) = Crossterm.left(col)
"""
Move cursor home
"""
move_cursor_home(::CrosstermTerminal) = Crossterm.to(; x = 0, y = 0)

"""
Clear screen
"""
clear_screen(::CrosstermTerminal) = Crossterm.clear()
"""
Clear screen from cursor up onwards
"""
clear_screen_from_cursor_up(::CrosstermTerminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_UP)
"""
Clear screen from cursor down onwards
"""
clear_screen_from_cursor_down(::CrosstermTerminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_DOWN)

"""
Clear line
"""
clear_line(::CrosstermTerminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)
"""
Clear line from cursor right onwards
"""
clear_line_from_cursor_right(::CrosstermTerminal) = Crossterm.clear(Crossterm.ClearType.UNTIL_NEW_LINE)
"""
Clear line from cursor left onwards
"""
clear_line_from_cursor_left(::CrosstermTerminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)

"""
Hide cursor
"""
hide_cursor(::CrosstermTerminal) = Crossterm.hide()
"""
Show cursor
"""
show_cursor(::CrosstermTerminal) = Crossterm.show()

"""
Save cursor
"""
save_cursor(::CrosstermTerminal) = Crossterm.save()
"""
Restore cursor
"""
restore_cursor(::CrosstermTerminal) = Crossterm.restore()

"""
Change cursor to default
"""
change_cursor_to_default(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.DEFAULT_USER_SHAPE)

"""
Change cursor to blinking block
"""
change_cursor_to_blinking_block(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.BLINKING_BLOCK)

"""
Change cursor to steady block
"""
change_cursor_to_steady_block(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.STEADY_BLOCK)
"""
Change cursor to blinking underline
"""
change_cursor_to_blinking_underline(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.BLINKING_UNDER_SCORE)
"""
Change cursor to steady underline
"""
change_cursor_to_steady_underline(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.STEADY_UNDER_SCORE)
"""
Change cursor to blinking ibeam
"""
change_cursor_to_blinking_ibeam(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.BLINKING_BAR)
"""
Change cursor to steady ibeam
"""
change_cursor_to_steady_ibeam(::CrosstermTerminal) = Crossterm.style(Crossterm.Style.STEADY_BAR)

"""
Alternate screen TUI mode
"""
tui_mode(::CrosstermTerminal) = Crossterm.alternate_screen(true)
"""
Default mode
"""
default_mode(::CrosstermTerminal) = Crossterm.alternate_screen(false)

"""
Get current buffer
"""
current_buffer(t::CrosstermTerminal)::Buffer = t.buffers[t.current[]]
current_buffer()::Buffer = current_buffer(TERMINAL[])

"""
Get previous buffer
"""
previous_buffer(t::CrosstermTerminal)::Buffer = t.buffers[t.previous[]]
previous_buffer()::Buffer = previous_buffer(TERMINAL[])

put(c::SubString{String}) = Crossterm.print(string(c))
put(c::Char) = Crossterm.print(c)
put(s::String) = Crossterm.print(s)
function put(cell::Cell)
  put(string(cell.style))
  put(cell.content)
  put(string(inv(cell.style)))
end

render(t::CrosstermTerminal, widget) = render(t, widget, area(t))
render(t::CrosstermTerminal, widget, r::Rect) = render(widget, r, current_buffer(t))

"""
Resize terminal
"""
function resize(t::CrosstermTerminal, w::Int, h::Int)
  rect = Rect(1, 1, w, h)
  t.terminal_size[] = rect
  t.buffers[t.current[]] = Buffer(rect)
  t.buffers[t.previous[]] = Buffer(rect)
end

"""
Area of terminal as Rect (width, height)
"""
function area(t::CrosstermTerminal)
  t.terminal_size[]
end

function tui(f::Function; flags...)
  r = nothing
  tui(true; flags...)
  try
    r = f()
  catch err
    tui(false; flags...)
    rethrow(err)
  finally
    tui(false; flags...)
  end
  return r
end

function tui(
  switch = true;
  log = true,
  enhance_keyboard = Sys.iswindows() ? false : true,
  mouse = false,
  flush = true,
  alternate_screen = true,
  raw_mode = true,
)
  flush && Crossterm.flush()
  if switch
    log && Logger.initialize()
    raw_mode && Crossterm.raw_mode(true)
    alternate_screen && Crossterm.alternate_screen(true)
    mouse && Crossterm.mouse_capture(true)
    enhance_keyboard && Crossterm.enhance_keyboard(true)
    Crossterm.hide()
  else
    Crossterm.show()
    enhance_keyboard && Crossterm.enhance_keyboard(false)
    mouse && Crossterm.mouse_capture(false)
    alternate_screen && Crossterm.alternate_screen(false)
    raw_mode && Crossterm.raw_mode(false)
    log && Logger.reset()
  end
  flush && Crossterm.flush()
end

