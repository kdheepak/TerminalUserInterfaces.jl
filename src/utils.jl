const BACKUP_STDIN_TERMIOS = Ref{TERMIOS.termios}()
const BACKUP_STDOUT_TERMIOS = Ref{TERMIOS.termios}()

const WIDTH = Ref{Int}()
const HEIGHT = Ref{Int}()
const MODE = Ref{Symbol}(:default)

function terminal_size(io)
    ws = IOCTL.ioctl(io, IOCTL.TIOCGWINSZ)
    # width, height
    return (Int(ws.ws_col), Int(ws.ws_row))
end

function terminal_size()
    ds = displaysize(stdout)
    return (last(ds), first(ds))
end

terminal_size(io, coord::Int) = terminal_size(io)[coord]
terminal_size(coord::Int) = terminal_size(stdout, coord)

const END = 2 + 1
const CONTROL_SEQUENCE_TIMEOUT = 100e-3

const INDICES = String["$i" for i in 1:1000]

struct CSI
    parameter::String
    immediate::String
    final::String
    _str::String
    CSI(parameter, immediate, final) =
        new(parameter, immediate, final, "$(Terminals.CSI)$(parameter)$(immediate)$(final)")
end

CSI(; parameter = "", immediate = "", final = "") = CSI(parameter, immediate, final)

Base.print(io::IO, csi::CSI) = print(io, csi._str)

const CLEARSCREEN = CSI(final = "2J")
const CLEARBELOWCURSOR = CSI(final = "J")
const CLEARABOVECURSOR = CSI(final = "1J")

const CLEARLINE = CSI(final = "2K")
const CLEARAFTERCURSOR = CSI(final = "K")
const CLEARBEFORECURSOR = CSI(final = "1K")

const HOMEPOSITION = CSI(final = "H")

const BELL = '\x07'

const HIDECURSOR = CSI(final = "?25l")
const SHOWCURSOR = CSI(final = "?25h")

const SAVECURSOR = CSI(final = "s")
const RESTORECURSOR = CSI(final = "u")

const LOCATECURSOR = CSI(final = "6n")

const RESET = "\ec"

const TUIMODE = CSI(final = "?1049h")
const DEFAULTMODE = CSI(final = "?1049l")

const CURSORBLINKINGBLOCK = CSI(final = "1 q")
const CURSORSTEADYBLOCK = CSI(final = "2 q")
const CURSORBLINKINGUNDERLINE = CSI(final = "3 q")
const CURSORSTEADYUNDERLINE = CSI(final = "4 q")
const CURSORBLINKINGIBEAM = CSI(final = "5 q")
const CURSORSTEADYIBEAM = CSI(final = "6 q")

clear_screen() = print(stdout, CLEARSCREEN)
clear_screen_from_cursor_up() = print(stdout, CLEARBELOWCURSOR)
clear_screen_from_cursor_down() = print(stdout, CLEARABOVECURSOR)

clear_line() = print(stdout, CLEARLINE)
clear_line_from_cursor_right() = print(stdout, CLEARAFTERCURSOR)
clear_line_from_cursor_left() = print(stdout, CLEARBEFORECURSOR)

hide_cursor() = print(stdout, HIDECURSOR)
show_cursor() = print(stdout, SHOWCURSOR)

save_cursor() = print(stdout, SAVECURSOR)
restore_cursor() = print(stdout, RESTORECURSOR)

move_cursor(row, col) = print(stdout, Terminals.CSI, INDICES[row], ';', INDICES[col], 'H')
move_cursor_up(row = 1) = print(stdout, Terminals.CSI, INDICES[row], 'A')
move_cursor_down(row = 1) = print(stdout, Terminals.CSI, INDICES[row], 'B')
move_cursor_right(col = 1) = print(stdout, Terminals.CSI, INDICES[col], 'C')
move_cursor_left(col = 1) = print(stdout, Terminals.CSI, INDICES[col], 'D')
move_cursor_home() = print(stdout, HOMEPOSITION)

change_cursor_to_blinking_block() = print(stdout, CURSORBLINKINGBLOCK)
change_cursor_to_steady_block() = print(stdout, CURSORSTEADYBLOCK)
change_cursor_to_blinking_underline() = print(stdout, CURSORBLINKINGUNDERLINE)
change_cursor_to_steady_underline() = print(stdout, CURSORSTEADYUNDERLINE)
change_cursor_to_blinking_ibeam() = print(stdout, CURSORBLINKINGIBEAM)
change_cursor_to_steady_ibeam() = print(stdout, CURSORSTEADYIBEAM)

reset() = print(stdout, RESET)

tui_mode() = print(stdout, TUIMODE)
default_mode() = print(stdout, DEFAULTMODE)

function with_raw_mode(f::Function)
    # if already in in raw mode don't enter raw mode again.
    # entering raw mode
    entered_raw_mode = false
    if MODE[] != :raw
        enable_raw_mode()
        entered_raw_mode = true
    end

    f()

    entered_raw_mode ? disable_raw_mode() : nothing
end

function detect_color(color::Integer)
    with_raw_mode() do
        print(stdout, "\x1B]4;$(color);?$(BELL)")
        Base.flush(stdout)
        total_read = 0
        now = time()
        c = 0x00
        bell = UInt8(BELL)
        channel = Channel(1)
        t = @async begin
            while c != bell
                c = read(stdin, 1)[]
                total_read += 1
            end
        end
        while c != bell && time() - now < CONTROL_SEQUENCE_TIMEOUT
            sleep(1e-3)
        end
        if !istaskdone(t)
            t.exception = InterruptException()
        end
    end
    return total_read > 0
end

function locate_cursor()
    location = UInt8[]
    with_raw_mode() do
        print(stdout, LOCATECURSOR)
        Base.flush(stdout)
        total_read = 0
        now = time()
        c = 0x00
        bell = UInt8(BELL)
        channel = Channel(1)
        t = @async begin
            while c != UInt8('R')
                c = read(stdin, 1)[]
                push!(location, c)
                total_read += 1
            end
        end
        while c != UInt8('R') && time() - now < CONTROL_SEQUENCE_TIMEOUT
            sleep(1e-3)
        end
        if !istaskdone(t)
            t.exception = InterruptException()
        end
    end
    row, col = split(String(Char.(location)[3:end-1]), ";")
    return parse(Int, row), parse(Int, col)
end

function enable_raw_mode()
    termios = TERMIOS.termios()
    TERMIOS.tcgetattr(stdin, termios)
     # Disable ctrl-c, disable CR translation, disable stripping 8th bit (unicode), disable parity
    termios.c_iflag &= ~(TERMIOS.BRKINT | TERMIOS.ICRNL | TERMIOS.INPCK | TERMIOS.ISTRIP | TERMIOS.IXON)
    # Disable output processing
    termios.c_oflag &= ~(TERMIOS.OPOST)
    # Disable parity
    termios.c_cflag &= ~(TERMIOS.CSIZE | TERMIOS.PARENB)
    # Set character size to 8 bits (unicode)
    termios.c_cflag |= (TERMIOS.CS8)
     # Disable echo, disable canonical mode (line mode), disable input processing, disable signals
    termios.c_lflag &= ~(TERMIOS.ECHO | TERMIOS.ICANON | TERMIOS.IEXTEN | TERMIOS.ISIG)
    termios.c_cc[TERMIOS.VMIN] = 0
    termios.c_cc[TERMIOS.VTIME] = 1
    TERMIOS.tcsetattr(stdin, TERMIOS.TCSANOW, termios)
end

function disable_raw_mode()
    TERMIOS.tcsetattr(stdin, TERMIOS.TCSANOW, BACKUP_STDIN_TERMIOS[])
    MODE[] = :default
end

function backup_termios()
    BACKUP_STDIN_TERMIOS[] = TERMIOS.termios()
    BACKUP_STDOUT_TERMIOS[] = TERMIOS.termios()
    TERMIOS.tcgetattr(stdin, BACKUP_STDIN_TERMIOS[])
    TERMIOS.tcgetattr(stdout, BACKUP_STDOUT_TERMIOS[])
end

function initialize()
    backup_termios()
    tui_mode()
    hide_cursor()
    enable_raw_mode()
    clear_screen()
    move_cursor_home()
end

function cleanup()
    move_cursor_home()
    clear_screen()
    disable_raw_mode()
    show_cursor()
    default_mode()
end
