using QXGraph
using Documenter

makedocs(;
    modules=[QXGraph],
    authors="QuantEx team",
    repo="https://github.com/JuliaQX/QXGraph.jl/blob/{commit}{path}#L{line}",
    sitename="QXGraph.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaQX.github.io/QXGraph.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaQX/QXGraph.jl",
)
