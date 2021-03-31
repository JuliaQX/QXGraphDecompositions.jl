using QXGraphDecompositions
using Documenter

DocMeta.setdocmeta!(QXGraphDecompositions, :DocTestSetup, :(using QXGraphDecompositions); recursive=true)
makedocs(;
    modules=[QXGraphDecompositions],
    authors="QuantEx team",
    repo="https://github.com/JuliaQX/QXGraphDecompositions.jl/blob/{commit}{path}#L{line}",
    sitename="QXGraphDecompositions.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaQX.github.io/QXGraphDecompositions.jl",
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
    repo="github.com/JuliaQX/QXGraphDecompositions.jl",
)
