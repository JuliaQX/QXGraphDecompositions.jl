import LightGraphs; lg = LightGraphs

export LabeledGraph
export get_vertex, vertices, nv, add_vertex!, rem_vertex!
export edges, ne, add_edge!, has_edge, rem_edge!
export degree, all_neighbors, eliminate!
export line_graph, combine_labels

# **************************************************************************************** #
#                          Labeled Graph Struct and interface
# **************************************************************************************** #

# TODO: It may be better to implement a subtype of AbstractGraph where the fadjlist
# is replaced with a dictionary of adjacency lists which can be indexed by symbols.
# This would avoid any iteration over vertices required for finding a vertex with a 
# particular label.

"""
Struct to represent a labeled graph. Unique symbols are created for each vertex if none are
provided and remain unaltered during the lifetime of the graph.

# Example
```julia-repl
julia> g = LabeledGraph()
LabeledGraph({0, 0} undirected simple Int64 graph, Symbol[])

julia> add_vertex!(g, :a_vertex_label)
1-element Array{Symbol,1}:
 :a_vertex_label

julia> g.labels[1]
:a_vertex_label
```
"""
struct LabeledGraph
    graph::lg.AbstractGraph
    labels::Vector{Symbol}

    LabeledGraph() = new(lg.SimpleGraph(), Symbol[])
    LabeledGraph(G::lg.AbstractGraph) = new(deepcopy(G), Symbol.([1:lg.nv(G)...]))
    LabeledGraph(G::lg.AbstractGraph, labels::Array{Symbol, 1}) = new(deepcopy(G), labels)
    LabeledGraph(N::Int) = LabeledGraph(lg.SimpleGraph(N))
end

"""
    get_vertex(G::LabledGraph, v_label)

Return the first vertex whose label matches the argument `v_label`. If an array of labels is
provided, an array of the corresponding vertices is return. 
"""
function get_vertex(G::LabeledGraph, v_label::Symbol)
    for v in vertices(G)
        if G.labels[v] == v_label
            return v
        end
    end
    nothing
end

function get_vertex(G::LabeledGraph, v_labels::Array{Symbol, 1})
    verts = Array{Int, 1}(undef, length(v_labels))
    for i = 1:length(verts)
        verts[i] = get_vertex(G, v_labels[i])
    end
    verts
end 

"""
    vertices(G::LabeledGraph)

Return the vertices of a labeled graph.
"""
function vertices(G::LabeledGraph)
    lg.vertices(G.graph)
end

"""
    nv(G::LabeledGraph)

Return the number of vertices in `G`.
"""
function nv(G::LabeledGraph)
    lg.nv(G.graph)
end

"""
    add_vertex!(G::LabeledGraph, label::Symbol)

Add a new vertex to `G` and assign the given label to it.
"""
function add_vertex!(G::LabeledGraph, label::Symbol)
    lg.add_vertex!(G.graph)
    append!(G.labels, Symbol[label])
end

"""
    rem_vertex!(G::LabeledGraph, v)

Delete the vertex with index or label `v` from `G`.
"""
function rem_vertex!(G::LabeledGraph, v::Int)
    lg.rem_vertex!(G.graph, v)
    G.labels[v] = G.labels[end]
    deleteat!(G.labels, length(G.labels))
end

function rem_vertex!(G::LabeledGraph, v_label::Symbol)
    v = get_vertex(G, v_label)
    if !(v === nothing)
        return rem_vertex!(G, v)
    end
    false
end

"""
    edges(G::LabeledGraph)

Return an iterator of the edges of `G`.
"""
function edges(G::LabeledGraph)
    lg.edges(G.graph)
end

"""
    ne(G::LabeledGraph)

Return the number of edges in `G`.
"""
function ne(G::LabeledGraph)
    lg.ne(G.graph)
end

"""
    add_edge!(G::LabeledGraph, u::Int, v::Int)

Add an edge to `G` connecting vertices `u` and `v`.
"""
function add_edge!(G::LabeledGraph, u::Int, v::Int)
    lg.add_edge!(G.graph, u, v)
end

function add_edge!(G::LabeledGraph, u_label::Symbol, v_label::Symbol)
    u = get_vertex(G, u_label)
    v = get_vertex(G, v_label)
    lg.add_edge!(G.graph, u, v)
end

"""
    has_edge(G::LabeledGraph, u::Int, v::Int)

Return true if `G` has an edge connecting vertices `u` and `v`. Return false otherwise.
"""
function has_edge(G::LabeledGraph, u::Int, v::Int)
    lg.has_edge(G.graph, u, v)
end

"""
    rem_edge!(G::LabeledGraph, u::Int, v::Int)

Remove the edge connecting vertices `u` and `v` if it exists.
"""
function rem_edge!(G::LabeledGraph, u::Int, v::Int)
    lg.rem_edge!(G.graph, u, v)
end

"""
    degree(G::LabeledGraph[, v])

Return an array containing the degree of each vertex of `G`. If `v` is specified, only 
return degrees for vertices in `v`.
"""
function degree(G::LabeledGraph)
    lg.degree(G.graph)
end

function degree(G::LabeledGraph, v::Union{Int, Array{Int, 1}})
    lg.degree(G.graph, v)
end

function degree(G::LabeledGraph, v_label::Union{Symbol, Array{Symbol, 1}})
    v = get_vertex(G, v_label)
    (v===nothing) ? false : lg.degree(G.graph, v)
end

"""
    all_neighbors(G::LabeledGraph, v::Int)

Return an array of all neighbors of `v` in `G`.
"""
function all_neighbors(G::LabeledGraph, v::Int)
    lg.all_neighbors(G.graph, v)
end

function all_neighbors(G::LabeledGraph, v_label::Symbol)
    v = get_vertex(G, v_label)
    lg.all_neighbors(G.graph, v)
end

"""
    eliminate!(G::LabledGraph, v)

Connect all the neighbors of `v` together before removing `v` from `G`.
"""
function eliminate!(G::LabeledGraph, v_label::Symbol)
    v = get_vertex(G, v_label)
    eliminate!(G, v)
end

function eliminate!(G::LabeledGraph, v::Integer)
    Nᵥ = all_neighbors(G, v)
    for (i, vi) in enumerate(Nᵥ)
        for ui in Nᵥ[i+1:end]
            add_edge!(G, vi, ui)
        end
    end
    rem_vertex!(G, v)
end

# **************************************************************************************** #
#                        Outer constructor for creating line graphs
# **************************************************************************************** #

"""
    line_graph(G)

Return a LabeledGraph representing the line graph of the 'G'. 

If 'G' is a LabeledGraph then a label for each each vertex of the line graph is created by 
concatenating the labels of the corresponding vertices in 'G'. Otherwise, labels are 
created by combining the indices of those vertices in 'G'.
"""
function line_graph(G::Union{lg.AbstractGraph, LabeledGraph})
    # Create a labeled graph LG whose vertices corresponding to the edges of G.
    if typeof(G) <: lg.AbstractGraph
        G_edges = collect(lg.edges(G))
        edge_labels = [(e.src, e.dst) for e in G_edges]
    else
        G_edges = collect(edges(G))
        edge_labels = [(G.labels[e.src], G.labels[e.dst]) for e in G_edges]
    end
    vertex_labels = [combine_labels(label[1], label[2]) for label in edge_labels]
    LG = LabeledGraph(lg.SimpleGraph(length(G_edges)), vertex_labels)

    # Connect any two vertices of LG whose corresponding edges in G share a vertex in G.
    for i in 1:length(G_edges)-1
        for j in i+1:length(G_edges)
            u = G_edges[i]
            v = G_edges[j]
            if (u.src == v.src) || (u.src == v.dst) || (u.dst == v.src) || (u.dst == v.dst)
                add_edge!(LG, i, j)
            end
        end
    end

    LG
end

"""
    combine_labels(label_A, label_B)

Concatenate 'label_A' and 'label_B' in lexicographical order. 
"""
function combine_labels(label_A, label_B)
    label_A < label_B ? Symbol(label_A, :_, label_B) : Symbol(label_B, :_, label_A)
end