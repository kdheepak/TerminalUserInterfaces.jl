keycode(evt::Crossterm.Event{Crossterm.KeyEvent}) = evt.data.code
keycode(_) = ""

keymodifier(evt::Crossterm.Event{Crossterm.KeyEvent}) = evt.data.modifiers

keypress(evt::Crossterm.Event{Crossterm.KeyEvent}) = evt.data.kind == "Press" ? keycode(evt) : ""
keypress(_) = ""
