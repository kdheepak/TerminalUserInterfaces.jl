module TerminalUserInterfaces

using REPL: Terminals
using Crossterm
using Crayons
using TextWrap

export Terminal

include("utils.jl")
include("symbols.jl")
include("layout.jl")
include("buffer.jl")
include("terminal.jl")
include("event.jl")

include("widgets/widgets.jl")

include("widgets/block.jl")

include("widgets/markdown.jl")
include("widgets/paragraph.jl")
include("widgets/progressbar.jl")
include("widgets/list.jl")
include("widgets/barchart.jl")
include("widgets/grid.jl")

end # module
