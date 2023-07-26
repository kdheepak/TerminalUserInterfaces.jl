import Base.print

"""
Terminal
"""
struct Terminal
  buffers::Vector{Buffer}
  current::Ref{UInt8}
  cursor_hidden::Ref{Bool}
  terminal_size::Ref{Rect}
  keyboard_buffer::Vector{Char}
  kind::String
  wait::Float64
  ispaused::Ref{Bool}
  isclosed::Ref{Bool}
  function Terminal()
    (; w, h) = Crossterm.size()
    rect = Rect(1, 1, w, h)
    buffers = [Buffer(rect), Buffer(rect)]
    current = 1
    cursor_hidden = false
    ispaused = Ref{Bool}(false)
    isclosed = Ref{Bool}(false)
    t = new(buffers, current, cursor_hidden, rect, Char[], get(ENV, "TERM", ""), 1 / 1000, ispaused, isclosed)
    TERMINAL[] = t
    return t
  end
end

function close(t::Terminal)
  t.isclosed[] = true
  t.ispaused[] = true
end

"""
Get event (nonblocking)
"""
function try_get_event(t::Terminal; wait = t.wait)
  if Crossterm.poll(wait)
    Crossterm.read()
  else
    nothing
  end
end

"""
Get event (blocking)
"""
function get_event(::Terminal)
  Crossterm.read()
end

const TERMINAL = Ref{Terminal}()

"""
Flush terminal contents
"""
function flush(t::Terminal)
  previous_buffer = t.buffers[END-t.current[]]
  current_buffer = t.buffers[t.current[]]
  draw(t, previous_buffer, current_buffer)
  update(t)
end

"""
Move cursor
"""
move_cursor(t::Terminal, row, col) = Crossterm.to(; x = col, y = row)
"""
Move cursor up
"""
move_cursor_up(t::Terminal, row = 1) = Crossterm.up(row)
"""
Move cursor down
"""
move_cursor_down(t::Terminal, row = 1) = Crossterm.down(row)
"""
Move cursor right
"""
move_cursor_right(t::Terminal, col = 1) = Crossterm.right(col)
"""
Move cursor left
"""
move_cursor_left(t::Terminal, col = 1) = Crossterm.left(col)
"""
Move cursor home
"""
move_cursor_home(t::Terminal) = Crossterm.to(; x = 0, y = 0)

"""
Clear screen
"""
clear_screen(t::Terminal) = Crossterm.clear()
"""
Clear screen from cursor up onwards
"""
clear_screen_from_cursor_up(t::Terminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_UP)
"""
Clear screen from cursor down onwards
"""
clear_screen_from_cursor_down(t::Terminal) = Crossterm.clear(Crossterm.ClearType.FROM_CURSOR_DOWN)

"""
Clear line
"""
clear_line(t::Terminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)
"""
Clear line from cursor right onwards
"""
clear_line_from_cursor_right(t::Terminal) = Crossterm.clear(Crossterm.ClearType.UNTIL_NEW_LINE)
"""
Clear line from cursor left onwards
"""
clear_line_from_cursor_left(t::Terminal) = Crossterm.clear(Crossterm.ClearType.CURRENT_LINE)

"""
Hide cursor
"""
hide_cursor(t::Terminal) = Crossterm.hide()
"""
Show cursor
"""
show_cursor(t::Terminal) = Crossterm.show()

"""
Save cursor
"""
save_cursor(t::Terminal) = Crossterm.save()
"""
Restore cursor
"""
restore_cursor(t::Terminal) = Crossterm.restore()

"""
Change cursor to default
"""
change_cursor_to_default(t::Terminal) = Crossterm.style(Crossterm.Style.DEFAULT_USER_SHAPE)

"""
Change cursor to blinking block
"""
change_cursor_to_blinking_block(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_BLOCK)

"""
Change cursor to steady block
"""
change_cursor_to_steady_block(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_BLOCK)
"""
Change cursor to blinking underline
"""
change_cursor_to_blinking_underline(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_UNDER_SCORE)
"""
Change cursor to steady underline
"""
change_cursor_to_steady_underline(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_UNDER_SCORE)
"""
Change cursor to blinking ibeam
"""
change_cursor_to_blinking_ibeam(t::Terminal) = Crossterm.style(Crossterm.Style.BLINKING_BAR)
"""
Change cursor to steady ibeam
"""
change_cursor_to_steady_ibeam(t::Terminal) = Crossterm.style(Crossterm.Style.STEADY_BAR)

"""
Alternate screen TUI mode
"""
tui_mode(t::Terminal) = Crossterm.alternate_screen(true)
"""
Default mode
"""
default_mode(t::Terminal) = Crossterm.alternate_screen(false)

"""
Get current buffer
"""
current_buffer(t::Terminal)::Buffer = t.buffers[t.current[]]
current_buffer()::Buffer = current_buffer(TERMINAL[])

"""
Reset terminal
"""
reset(t::Terminal, buffer::Int) = reset(t.buffers[buffer])

const END = 2 + 1

"""
Update terminal
"""
function update(t::Terminal)
  reset(t.buffers[END-t.current[]])
  t.current[] = END - t.current[]
  (w, h) = size(t)
  if t.terminal_size[].width != w || t.terminal_size[].height != h
    resize(t, w, h)
    clear_screen(t)
    move_cursor_home(t)
  end
end

put(c::Char) = Crossterm.print(string(c))
put(s::String) = Crossterm.print(s)
function put(cell::Cell)
  put(string(cell.style))
  put(cell.char)
  put(string(inv(cell.style)))
end

"""
Draw terminal
"""
function draw(t::Terminal, buffer1::Buffer, buffer2::Buffer)
  save_cursor(t)
  move_cursor_home(t)
  R, C = Base.size(buffer2.content)
  for r in 1:R, c in 1:C
    if buffer1.content[r, c] != buffer2.content[r, c]
      move_cursor(t, r, c)
      cell = buffer2.content[r, c]
      put(cell)
    end
  end
  restore_cursor(t)
  Crossterm.flush()
end

"""
Resize terminal
"""
function resize(t::Terminal, w::Int, h::Int)
  rect = Rect(1, 1, w, h)
  t.terminal_size[] = rect
  t.buffers[1] = Buffer(rect)
  t.buffers[2] = Buffer(rect)
end

"""
Size of terminal as a tuple (width, height)
"""
function size(t::Terminal)
  (; w, h) = Crossterm.size()
  (w, h)
end
