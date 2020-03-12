module IOCTL

const TIOCGETP = Sys.islinux() ? 0 : 1074164744 # Get parameters -- V6/V7 gtty()
const TIOCSETP = Sys.islinux() ? 1 : -2147060727 # Set parameters -- V6/V7 stty()

const TIOCSETN = 2 # V7:   as above, but no flushtty
const TIOCEXCL = 3 # V7: set exclusive use of tty
const TIOCNXCL = 4 # V7: reset excl. use of tty
const TIOCHPCL = 5 # V7: hang up on last close
const TIOCFLUSH = 6 # V7: flush buffers

const TIOCSTI = 7 # simulate terminal input
const TIOCSBRK = 8 # set   break bit
const TIOCCBRK = 9 # clear break bit
const TIOCSDTR = 10 # set   data terminal ready
const TIOCCDTR = 11 # clear data terminal ready
const TIOCGPGRP = 12 # get pgrp of tty
const TIOCSPGRP = 13 # set pgrp of tty
const TIOCGETC = Sys.islinux() ? 14 : 1074164754 # get special characters
const TIOCSETC = Sys.islinux() ? 15 : -2147060719 # set special characters
const TIOCLBIS = Sys.islinux() ? 16 : 0x8004747f # set   bits in local mode word
const TIOCLBIC = Sys.islinux() ? 17 : 0x8004747e # clear bits in local mode word
const TIOCLGET = Sys.islinux() ? 18 : 0x8004747c # get local mode mask
const TIOCLSET = Sys.islinux() ? 19 : 0x8004747d # set local mode mask
const TIOCSLTC = Sys.islinux() ? 20 : -2147060619 # set local special chars
const TIOCGLTC = Sys.islinux() ? 21 : 1074164852 # get local special chars

const TCGETP = 1076130901
const TCGETA = 1075082331
const TCSETAW = -2146143143

const FIONREAD = 22 # get # bytes to read

const TIOCGETD = 23 # Get line discipline
const TIOCSETD = 24 # Set line discipline

const TIOCGWINSZ = Sys.islinux() ? 25 : 1074295912 # Get window size info
const TIOCSWINSZ = 26 # Set window size info (maybe gen SIGWINCH)

const ALLDELAY =0177400 # Delay algorithm selection
const BSDELAY = 0100000 # Select backspace delays
const BS0 = 0
const BS1 = 0100000
const VTDELAY = 040000 # for,-feed/v-tab delay
const FF0 = 0
const FF1 = 040000
const CRDELAY = 030000 # carriage-return delay
const CR0 = 0
const CR1 = 010000
const CR2 = 020000
const CR3 = 030000
const TBDELAY = 06000 # tab delays
const TAB0 = 0
const TAB1 = 01000
const TAB2 = 04000
const XTABS = 06000
const NLDELAY = 01400 # new-line delays
const NL0 = 0
const NL1 = 0400
const NL2 = 01000
const NL3 = 01400
const EVENP = 0200 # even parity allowed on input
const ODDP = 0100 # odd parity allowed on input
const RAW = 040 # wake on all chars, 8-bit input
const CRMOD = 020 # map CR->LF; echo LF or CR as CRLF
const ECHO = 010 # echo (full duplex)
const LCASE = 04 # map upper case to lower case
const CBREAK = 02 # return each char as soon as typed
const TANDEM = 01 # automatic flow control

const LCRTBS = 01 # Backspace on erase rather than echoing erase
const LPRTERA = 02 # Printing terminal erase mode
const LCRTERA = 04 # Erase char echoes as BS-SP-BS
const LTILDE = 010 # Convert ~ to ` on output (for Hazeltines)
const LMDMBUF = 020 # Stop/start output when carrier drops
const LLITOUT = 040 # Suppress output translations
const LTOSTOP = 0100 # Send SIGTTOU for background output
const LFLUSHO = 0200 # Output is being flushed
const LNOHANG = 0400 # Don't send hangup when carrier drops
const LETXACK = 01000 # Diablo style buffer hacking (??)
const LCRTKIL = 02000 # Use BS-SP-BS to erase entire line on line kill
const LINTRUP = 04000 # Generate SIGTINT when input ready to read
const LCTLECH = 010000 # Echo input control chars as ^X (DEL as ^?)
const LPENDIN = 020000 # Retype pending input at next read or input char
const LDECCTQ = 040000 # Only ^Q restarts after ^S, like DEC systems

const OTTYDISC = 0 # Old V7-style discipline (must be zero)
const NTTYDISC = 1 # New BSD-style discipline
const NETLDISC = 2 # high-speed "net" discipline (not supported)


struct winsize
    ws_row::UInt16
    ws_col::UInt16
    ws_xpixel::UInt16
    ws_ypixel::UInt16
end

struct tchars
    t_intrc::UInt8 # interrupt
    t_quitc::UInt8 # quit
    t_startc::UInt8 # start output
    t_stopc::UInt8 # stop output
    t_eofc::UInt8 # end-of-file
    t_brkc::UInt8 # input delimiter (like nl)
end

struct ltchars
    t_suspc::UInt8 # /* stop process signal */
    t_dsuspc::UInt8 # /* delayed stop process signal */
    t_rprntc::UInt8 # /* reprint line */
    t_flushc::UInt8 # /* flush output (toggles) */
    t_werasc::UInt8 # /* word erase */
    t_lnextc::UInt8 # /* literal next character */
end


_file_handle(s::Base.LibuvStream) = ccall(:jl_uv_file_handle, Base.OS_HANDLE, (Ptr{Cvoid},), s.handle)

function ioctl(fd::RawFD, parameter::Int)
    ws = Ref{winsize}()
    r = ccall(:ioctl, Cint, (Cint, Cint, Ptr{Cvoid}), fd, parameter, ws)
    r == -1 ? error("ioctl failed: $(Base.Libc.strerror())") : nothing
    return ws[]
end
ioctl(s::Base.LibuvStream, parameter) = ioctl(_file_handle(s), parameter)
ioctl(f::Int, parameter) = ioctl(RawFD(f), parameter)

end
