module TerminalUserInterfaces

using REPL: Terminals
using Crossterm
using Crayons
using TextWrap
using Unicode
using InlineTest
using KiwiConstraintSolver
using Tables

export Terminal

const TUI = TerminalUserInterfaces

include("logger.jl")
include("symbols.jl")
include("layout.jl")
include("buffer.jl")
include("terminal.jl")
include("event.jl")

include("widgets/widgets.jl")

include("widgets/block.jl")
include("widgets/layout.jl")

include("widgets/barchart.jl")
include("widgets/grid.jl")
include("widgets/list.jl")
include("widgets/markdown.jl")
include("widgets/paragraph.jl")
include("widgets/progressbar.jl")
include("widgets/scrollbar.jl")
include("widgets/table.jl")

include("app.jl")

end # module
