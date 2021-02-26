```@meta
CurrentModule = QXGraph
```

# QXGraph

QXGraph is a Julia package for analysing and manipulating graph structures describing tensor 
networks in the QuantEx project. It provides functions for solving graph theoretic problems 
related to the task of efficiently slicing and contracting a tensor network.

QXGraph was developed as part of the QuantEx project, one of the individual software 
projects of WP8 of [PRACE](https://prace-ri.eu/) 6IP.


## Getting started

### Installation

QXGraph is a Julia package and can be installed using Julia's inbuilt package manager from 
the Julia REPL using.

```
import Pkg
Pkg.install("QXGraph")
```

### Example usage

An example of how QXGraph can be used to calculate a vertex elimination order for a graph
looks like:

```
using QXGraph

# Create a LabeledGraph with N fully connected vertices
N = 10
G = LabeledGraph(N)
for i = 1:N, j = i+1:N
    add_edge!(G, i, j)
end

# To get an elimination order for G with minimal treewidth we call quickbb
elimination_order, md = quickbb(G)
@show elimination_order

# The treewidth of the elimination order is contained in the metadata dictionary by quickbb
@show md[:treewidth]
```

For more information about the algorithms made available by QXGraph please consult the contents below.


### Contents

  - [Treewidth Algorithms](@ref) Describes useful algorithms for analysing a tensor network's line graph.
  - [Labeled Graphs](@ref) Describes the QXGraph `LabeledGraph` struct for representing graphs.