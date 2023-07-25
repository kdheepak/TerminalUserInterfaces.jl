keycode(evt::Crossterm.Event{Crossterm.KeyEvent}) = evt.data.code
keycode(_) = ""

keymodifier(evt::Crossterm.Event{Crossterm.KeyEvent}) = evt.data.modifiers
