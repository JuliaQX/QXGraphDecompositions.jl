# QXGraphDecompositions

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaQX.github.io/QXGraphs.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaQX.github.io/QXGraphs.jl/dev)
[![Build Status](https://github.com/JuliaQX/QXGraphs.jl/workflows/CI/badge.svg)](https://github.com/JuliaQX/QXGraphs.jl/actions)
<!-- [![Build Status](https://github.com/JuliaQX/QXGraphs.jl/badges/master/pipeline.svg)](https://github.com/JuliaQX/QXGraphs.jl/pipelines)
[![Coverage](https://github.com/JuliaQX/QXGraphs.jl/badges/master/coverage.svg)](https://github.com/JuliaQX/QXGraphs.jl/commits/master) -->
[![Coverage](https://codecov.io/gh/JuliaQX/QXGraphs.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaQX/QXGraphs.jl)


QXGraphDecompositions is a Julia package for analysing and manipulating graph structures describing tensor 
networks in the QuantEx project. It provides functions for solving graph theoretic problems 
related to the task of efficiently slicing and contracting a tensor network.

QXGraphDecompositions was developed as part of the QuantEx project, one of the individual software 
projects of WP8 of [PRACE](https://prace-ri.eu/) 6IP.

# Installation

QXGraphDecompositions is a Julia package and can be installed using Julia's inbuilt package manager from 
the Julia REPL using.

```
import Pkg
Pkg.add("QXGraphDecompositions")
```

To ensure everything is working, the unittests can be run using

```
import Pkg; Pkg.test()
```

## Example usage

An example of how QXGraphDecompositions can be used to calculate a vertex elimination order for a graph
looks like:

```
using QXGraphDecompositions

# Create a LabeledGraph with N fully connected vertices.
N = 10
G = LabeledGraph(N)
for i = 1:N, j = i+1:N
    add_edge!(G, i, j)
end

# To get an elimination order for G with minimal treewidth we call quickbb.
elimination_order, md = quickbb(G)
@show elimination_order

# The treewidth of the elimination order is contained in the metadata dictionary returned by quickbb.
@show md[:treewidth]
```

# Contributing
Contributions from users are welcome and we encourage users to open issues and submit 
merge/pull requests for any problems or feature requests they have. The 
[CONTRIBUTING.md](CONTRIBUTION.md) has further details of the contribution guidelines.


## Building documentation

QXTn.jl uses [Documenter.jl](https://juliadocs.github.io/Documenter.jl/stable/) to generate documentation. To build the documentation locally run the following from the root folder.

The first time it is will be necessary to instantiate the environment to install dependencies

```
julia --project=docs/ -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
```

and then to build the documentation

```
julia --project=docs/ docs/make.jl
```

The generated document will be in the `docs/build` folder. To serve these locally one can
use the LiveServer package as

```
julia --project -e 'import Pkg; Pkg.add("LiveServer");
julia --project -e  'using LiveServer; serve(dir="docs/build")'
```

Or with python3 using from the `docs/build` folder using

```
python3 -m http.server
```

The generated documentation should now be viewable locally in a browser at `http://localhost:8000`.