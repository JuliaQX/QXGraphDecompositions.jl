# Treewidth Algorithms

One strategy for building contraction plans for tensor networks involves finding a vertex 
elimination order for the network's line graph. The treewidth of a graph, with respect to a
vertex elimination order, is the maximum number of neighbours a vertex has in the graph when
it is eliminated according the order. In the context of tensor network contraction, 
treewidth serves as an indirect measure of the size of the largest intermediate tensor 
produced while contracting a network according to a the contraction plan built from the
elimination order. It is thus also an indirect measure of the computational cost of 
contracting a tensor network according to the corresponding contraction plan. QXGraph 
provides functions for finding such elimination orders with minimal treewidth.

## Vertex Elimination Orders

A standard algorithm for finding elimination orders, whose treewidth provides a good upper
bound for the minimal treewidth of a graph, is known as the QuickBB algorithm.
It was first proposed by Vibhav Gogate and Rina Dechter in their 2004 paper "A complete 
Anytime Algorithm for Treewidth". The paper along with a binary implementation of the 
algorithm is provided [here](http://www.hlt.utdallas.edu/~vgogate/quickbb.html). QXGraph
provides a julia wrapper for their binary which requires a linux OS.

```@docs
quickbb
graph_to_cnf
```

#### Partial Elimination order

The following functions can be used to create an elimination order for a graph $G$ with a 
specified clique of $G$ appearing at the end of the order. This is useful for finding
contraction plans for tensor networks containing open indices. The algorithm and application
of these functions is described further by Shutski et al in 
[this](https://arxiv.org/abs/1911.12242) paper.

```@docs
build_chordal_graph
restricted_mcs
```

Given an elimination order $\pi$ for a particualr graph $G$, the treewidth of $G$ with 
respect to the order $\pi$ can be computed using the following function.

```@docs
find_treewidth_from_order
```

## Treewidth deletion

The problem of finding a select number of vertices in a graph to delete, in order to reduce
the treewidth of the graph, is known as the treewidth deletion problem. A method for 
solving this problem, implemented by the functions below, and it's application to tensor 
network slicing is discussed by Shutski et al [here](https://journals.aps.org/pra/abstract/10.1103/PhysRevA.102.062614).

```@docs
greedy_treewidth_deletion
direct_treewidth_score
```