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
        "Labeled Graphs" => "LabeledGraph.md",
        "Treewidth" => "treewidth.md",
        "Index" => "docs_index.md",
        "LICENSE" => "license.md"
    ],
)

deploydocs(;
    repo="github.com/JuliaQX/QXGraph.jl",
)