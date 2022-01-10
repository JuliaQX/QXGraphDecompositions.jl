```@meta
CurrentModule = QXGraphDecompositions
```

# QXGraphDecompositions

QXGraphDecompositions is a Julia package for analysing and manipulating graph structures 
describing tensor networks. It provides functions for solving graph theoretic problems 
related to the task of efficiently slicing and contracting a tensor network.

QXGraphDecompositions was developed as part of the [QuantEx](https://github.com/JuliaQX/QXTools.jl) project, one of the individual 
software projects of WP8 of [PRACE](https://prace-ri.eu/) 6IP.


## Getting started

### Installation

QXGraphDecompositions is a Julia package and can be installed using Julia's inbuilt package 
manager from the Julia REPL using.

```
import Pkg
Pkg.add("QXGraphDecompositions")
```

To ensure everything is working, the unittests can be run using

```
import Pkg; Pkg.test()
```

### Example usage

An example of how QXGraphDecompositions can be used to calculate a vertex elimination order 
for a graph looks like:

```
using QXGraphDecompositions

# Create a LabeledGraph with N fully connected vertices.
N = 10
G = LabeledGraph(N)
for i = 1:N, j = i+1:N
    add_edge!(G, i, j)
end

# To get an elimination order for G with minimal treewidth we can use the min fill heuristic.
# tw, elimination_order = min_fill(G);
@show elimination_order

# The treewidth of the elimination order is:
@show tw
```

For more information about the algorithms made available by QXGraphDecompositions please 
consult the contents below.


### Contents

  - [Treewidth Algorithms](@ref) Describes useful algorithms for analysing a tensor network's line graph.
  - [Labeled Graphs](@ref) Describes the QXGraphDecompositions `LabeledGraph` struct for representing graphs.
