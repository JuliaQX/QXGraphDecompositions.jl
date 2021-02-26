# QXGraph

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaQX.github.io/QXGraph.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaQX.github.io/QXGraph.jl/dev)
[![Build Status](https://github.com/JuliaQX/QXGraph.jl/workflows/CI/badge.svg)](https://github.com/JuliaQX/QXGraph.jl/actions)
[![Build Status](https://github.com/JuliaQX/QXGraph.jl/badges/master/pipeline.svg)](https://github.com/JuliaQX/QXGraph.jl/pipelines)
[![Coverage](https://github.com/JuliaQX/QXGraph.jl/badges/master/coverage.svg)](https://github.com/JuliaQX/QXGraph.jl/commits/master)
[![Coverage](https://codecov.io/gh/JuliaQX/QXGraph.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaQX/QXGraph.jl)


QXGraph is a Julia package for analysing and manipulating graph structures describing tensor 
networks in the QuantEx project. It provides functions for solving graph theoretic problems 
related to the task of efficiently slicing and contracting a tensor network.

QXGraph was developed as part of the QuantEx project, one of the individual software 
projects of WP8 of [PRACE](https://prace-ri.eu/) 6IP.

# Installation

QXGraph is a Julia package and can be installed using Julia's inbuilt package manager from 
the Julia REPL using.

```
import Pkg
Pkg.install("QXGraph")
```

## Running the unittests

Unittests can be run from the QXGraph root folder with

```
julia --project=. tests/runtests.jl
```

# Contributing
Contributions from users are welcome and we encourage users to open issues and submit 
merge/pull requests for any problems or feature requests they have. The 
[CONTRIBUTING.md](CONTRIBUTION.md) has further details of the contribution guidelines.

## Building the documentation

This package uses Documenter.jl to generate html documentation from the sources.
To build the documentation, run the make.jl script from the docs folder.

```
cd docs && julia make.jl
```

The documentation will be placed in the build folder and can be hosted locally
by starting a local http server with

```
cd build && python3 -m http.server
```