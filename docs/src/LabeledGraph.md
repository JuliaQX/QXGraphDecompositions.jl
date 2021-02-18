# Labeled Graphs

QXGraph uses the `SimpleGraph` struct from the LightGraphs package to store graph structures. 
However, some of the algorithms implemented in QXGraph repeatedly modify the graph they work 
on, either by removing or adding vertices in varying orders, and in turn alter the manner in 
which vertices in the graph are indexed. This can make it difficult to track where vertices
end up in a graph after many modifications are made, which needs to be done if the vertices
are used to index different variables in an alternate data structure, such as indices or 
tensors in a tensor network. To this end, QXGraph defines a LabeledGraph struct which pairs
a `SimpleGraph` with and array of julia symbols which can be used to identify vertices in
a graph after modifications have been made. 

```@docs
LabeledGraph
```

### LabeledGraph Interface

```@docs
get_vertex
vertices
nv
add_vertex!
rem_vertex!
edges
ne
add_edge!
has_edge
rem_edge!
degree
all_neighbors
eliminate!
```

### Line Graph

```@docs
line_graph
combine_labels
```