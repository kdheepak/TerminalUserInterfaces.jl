module TerminalUserInterfaces

using REPL: Terminals
using TERMIOS
using Crayons
using TextWrap

export Terminal

include("ioctl.jl")
include("utils.jl")

include("symbols.jl")

include("layout.jl")
include("buffer.jl")

include("events.jl")

include("terminal.jl")

include("widgets/widgets.jl")

include("widgets/block.jl")

include("widgets/markdown.jl")
include("widgets/paragraph.jl")
include("widgets/progressbar.jl")
include("widgets/list.jl")
include("widgets/barchart.jl")
include("widgets/grid.jl")

end # module
