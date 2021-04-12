# Treewidth Algorithms

To efficiently contract a tensor network, it is essential to find an order to contract the 
tensors in (which we refer to as a contraction plan) which is computationally feasible. It 
was shown by [Markov and Shi](https://arxiv.org/abs/quant-ph/0511069) that a contraction
plan for a network can be mapped to a [tree decomposition](https://en.wikipedia.org/wiki/Tree_decomposition) 
of the network's line graph. The computational cost of the contraction plan is then
exponential in the treewidth of that tree decomposition.

In this context, the treewidth of a tree decomposition, for a networks line graph, serves as 
an indirect measure of the size of the largest intermediate tensor produced while 
contracting a network according to a contraction plan that maps to the tree decompositon. As 
the cost of contracting a network is dominated by contractions involing the largest 
intermediate tensor, it is thus also an indirect measure of the computational cost of the 
contraction plan used.

The problem of finding a computationally feasible contraction plan for a tensor network can
be solved by searching for tree decompositions, or equivalently vertex elimination orderings,
that minimise the treewidth. QXGraphDecompositions provides functions for finding such tree 
decompositions and vertex elimination orders.

## Tree Decompositions

An algorithm for finding tree decompositions with minimal treewidth was developed at 
[KIT](https://www.kit.edu) in the [group of Prof. Dorothea Wagner](https://i11www.iti.kit.edu) 
is available [here](https://github.com/kit-algo/flow-cutter-pace17). QXGraphDecompositions 
uses the [FlowCutterPACE17_jll](https://github.com/JuliaBinaryWrappers/FlowCutterPACE17_jll.jl) 
wrapper package to provide the following function for computing such a tee decompostion of a
graph.

```@docs
flow_cutter
```


## Vertex Elimination Orders

An equivalent strategy for finding contraction plans for tensor networks involves finding an 
order in which to eliminate the vertices in the network's line graph. Here, eliminating a
vertex from a graph means connecting all of its neighbours together before removing it from
the graph. Vertex elimination orders can be mapped to tree decompositions and have an
equivalent notion of treewidth. The treewidth of a graph, with respect to a vertex 
elimination order, is the maximum number of neighbours a vertex has in the graph when it is 
eliminated according the order.

A standard algorithm for finding elimination orders, whose treewidth provides a good upper
bound for the minimal treewidth of a graph, is known as the QuickBB algorithm.
It was first proposed by Vibhav Gogate and Rina Dechter in their 2004 paper "A complete 
Anytime Algorithm for Treewidth". The paper along with a binary implementation of the 
algorithm is provided [here](http://www.hlt.utdallas.edu/~vgogate/quickbb.html). 
QXGraphDecompositions provides a julia wrapper for their binary which requires a linux OS.

```@docs
quickbb
```

The min-fill heuristic is a popular heuristic for computing an upper bound on treewidth of
a graph and an elimination order with the returned treewidth.

```@docs
min_fill
```

The following function can be used to recover a vertex elimination order from a tree 
decomposition whose treewidth equals that of the tree decomposition. The provided tree
decompositon is assumed to be contained in a dictionary similar to the one returned by the
flow cutter algorithm.

```@docs
order_from_tree_decomposition
```

Given an elimination order $\pi$ for a particualr graph $G$, the treewidth of $G$ with 
respect to the order $\pi$ can be computed using the following function.

```@docs
find_treewidth_from_order
```

The following functions can be used to create an elimination order for a graph $G$ with a 
specified clique of $G$ appearing at the end of the order. This is useful for finding
contraction plans for tensor networks containing open indices. The algorithm and application
of these functions is described further by Shutski et al in [this](https://arxiv.org/abs/1911.12242) paper.

```@docs
restricted_mcs
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