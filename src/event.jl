
const ResizeEvent = Crossterm.Event{Crossterm.ResizeEvent}
const KeyEvent = Crossterm.Event{Crossterm.KeyEvent}
const MouseEvent = Crossterm.Event{Crossterm.MouseEvent}
keycode(evt::KeyEvent) = evt.data.code
keycode(_) = ""

keymodifier(evt::KeyEvent) = evt.data.modifiers

keypress(evt::KeyEvent) = evt.data.kind == "Press" ? keycode(evt) : ""
keypress(_) = ""
