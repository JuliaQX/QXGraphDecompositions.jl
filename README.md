# QXGraph

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaQX.github.io/QXGraph.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaQX.github.io/QXGraph.jl/dev)
[![Build Status](https://github.com/JuliaQX/QXGraph.jl/workflows/CI/badge.svg)](https://github.com/JuliaQX/QXGraph.jl/actions)
[![Build Status](https://github.com/JuliaQX/QXGraph.jl/badges/master/pipeline.svg)](https://github.com/JuliaQX/QXGraph.jl/pipelines)
[![Coverage](https://github.com/JuliaQX/QXGraph.jl/badges/master/coverage.svg)](https://github.com/JuliaQX/QXGraph.jl/commits/master)
[![Coverage](https://codecov.io/gh/JuliaQX/QXGraph.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaQX/QXGraph.jl)


A Julia package to analyse and manipulate graph structures for the QuantEx project. 
QXGraph.jl provides functions for solving graph theoretic problems related to the task of 
slicing and contracting a tensor network.

QXGraph.jl integrates with QXSim.jl to perform full end-to-end demonstrations of quantum 
circuit simulation as part of the QuantEx project.

## Running the unittests

Unittests can be run from the QXGraph root folder with

```
julia --project=. tests/runtests.jl
```

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