# Labeled Graphs

QXGraphDecompositions uses the `SimpleGraph` struct from the LightGraphs package to store 
graph structures. However, some of the algorithms implemented in QXGraphDecompositions 
repeatedly modify the graph they work on, either by removing or adding vertices in varying 
orders, and in turn alter the manner in which vertices in the graph are indexed. This can 
make it difficult to track where vertices end up in a graph after many modifications are 
made, which needs to be done if the vertices are used to index different variables in an 
alternate data structure, such as indices or tensors in a tensor network. To this end, 
QXGraphDecompositions defines a LabeledGraph struct which pairs a `SimpleGraph` with and 
array of julia symbols which can be used to identify vertices in a graph after modifications 
have been made. 

```@docs
LabeledGraph
```

## Example usage

An example of how to use LabeledGraphs is shown below. Note, whenever a modification is made
to the graph which re-indexes or re-positions the vertices in the graph, the array of vertex 
labels in the LabeledGraph is also updated to reflect the reordering. Hence, when a sequence
of modifications is made to the graph, we can identify how the vertices of the original 
graph are now indexed in the new graph by looking at how the corresponding labels are 
indexed inside the LabeledGraph.

```
using QXGraphDecompositions

# Create a LabeledGraph with N vertices
N = 10
G = LabeledGraph(N)

# Display the label assigned to the first and last vertices in the graph.
@show G.labels[1]
@show G.labels[end]

# Remove the first vertex in the graph. To remove a vertex, LightGraphs first swaps the 
# positions of the vertex being removed and the last vertex and then removes the last vertex.
rem_vertex!(G, 1)

# Display the label which is now assigned to the first vertex in the graph.
@show G.labels[1]
```

## LabeledGraph Interface

The interface for the LabeledGraph struct is intended to reflect the interface implemented 
by the LightGraphs package for the SimpleGraph struct.

```@docs
labels
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
cliqueness
```

## LabeledGraph Constructors

```@docs
line_graph
tree_from_tree_decompostion
chordal_graph
```

## LabeledGraph IO

```@docs
graph_to_gr
graph_to_cnf
```