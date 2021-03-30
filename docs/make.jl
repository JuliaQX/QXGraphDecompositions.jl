using QXGraphs
using Documenter

DocMeta.setdocmeta!(QXGraphs, :DocTestSetup, :(using QXGraphs); recursive=true)
makedocs(;
    modules=[QXGraphs],
    authors="QuantEx team",
    repo="https://github.com/JuliaQX/QXGraphs.jl/blob/{commit}{path}#L{line}",
    sitename="QXGraphs.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaQX.github.io/QXGraphs.jl",
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
    repo="github.com/JuliaQX/QXGraphs.jl",
)
