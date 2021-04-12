import LightGraphs; lg = LightGraphs

export LabeledGraph, labels, graph_to_gr, graph_to_cnf
export get_vertex, vertices, nv, add_vertex!, rem_vertex!
export edges, ne, add_edge!, has_edge, rem_edge!
export degree, all_neighbors, eliminate!, cliqueness
export line_graph, tree_from_tree_decompostion, chordal_graph



# **************************************************************************************** #
#                                  Labeled Graph Struct
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
    LabeledGraph(labels::Array{Symbol, 1}) = new(lg.SimpleGraph(length(labels)), labels)
end


"""
    graph_to_gr(G::LabeledGraph, filename::String)

Write the provided graph to a file in gr format.
"""
graph_to_gr(G::LabeledGraph, filename::String) = graph_to_gr(G.graph, filename::String)

function graph_to_gr(G::lg.AbstractGraph, filename::String)
    open(filename, "w") do io
        write(io, "p tw $(lg.nv(G)) $(lg.ne(G))\n")
        for e in lg.edges(G)
            write(io, "$(e.src) $(e.dst)\n")
        end
    end
end


"""
    graph_to_cnf(G::LabeledGraph, filename::String)

Write the provided graph to a file in cnf format.
"""
graph_to_cnf(G::LabeledGraph, filename::String) = graph_to_cnf(G.graph, filename::String)

function graph_to_cnf(G::lg.AbstractGraph, filename::String)
    open(filename, "w") do io
        write(io, "p cnf $(lg.nv(G)) $(lg.ne(G))\n")
        for e in lg.edges(G)
            write(io, "$(e.src) $(e.dst) 0\n")
        end
    end
end



# **************************************************************************************** #
#                                Labeled Graph Interface
# **************************************************************************************** #

"""
    labels(G::LabeledGraph)

Return the labels contained in a LabeledGraph.
"""
labels(G::LabeledGraph) = G.labels

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

"""
    eliminate!(G::AbstractGraph, v::Integer)

Connect all the neighbours of v together before removing v from G.
"""
function eliminate!(G::LabeledGraph, v::Integer)
    # Loop over all pairs of neighbours (vi, ui) of v and try connect them with an edge
    # before removing v from G.
    Nᵥ = all_neighbors(G, v)::Array{Int64, 1}
    for i in 1:length(Nᵥ)
        vi = Nᵥ[i]
        for j in i+1:length(Nᵥ)
            uj = Nᵥ[j]
            add_edge!(G, vi, uj)
        end
    end
    rem_vertex!(G, v)
end

"""
    eliminate!(G::AbstractGraph, v::Integer, c_map::Dict{Int, Int})

Connect all the neighbours of v together before removing v from G. 

The dictionary `c_map` mapping vertices of 'G' to their cliqueness is updated inplace 
accordingly.
"""
function eliminate!(G::LabeledGraph, v::Integer, c_map::Dict{Int, Int})
    Nᵥ = all_neighbors(G, v)::Array{Int64, 1}
    # Loop over all pairs of vertices in the neighbourhood of 'v'.
    for i in 1:length(Nᵥ)
        vi = Nᵥ[i]
        for j in i+1:length(Nᵥ)
            ui = Nᵥ[j]

            # Try add an edge connecting vi and ui. If successful, update `c_map`.
            edge_added = add_edge!(G, vi, ui)::Bool
            if edge_added
                # Common neighbours of vi and ui have one less edge to add
                # when being eliminated after vi and ui are connected.
                Nvi = all_neighbors(G, vi)::Array{Int64, 1}
                Nui = all_neighbors(G, ui)::Array{Int64, 1}
                for n in intersect(Nvi, Nui)
                    c_map[n] -= 1
                end

                # ui and vi are now neighbours so their cliqueness may increase.
                for n in Nvi
                    if !(n == ui) && !(has_edge(G, n, ui)::Bool)
                        c_map[vi] += 1
                    end
                end
                for n in Nui
                    if !(n == vi) && !(has_edge(G, n, vi)::Bool)
                        c_map[ui] += 1
                    end
                end
            end
        end
    end

    # Removing v from G means it's also removed from its neighbour's neighbourhood, so their 
    # cliqueness may be reduced.
    for n in Nᵥ
        Nₙ = all_neighbors(G, n)::Array{Int64, 1}
        for u in Nₙ
            if !(u == v)
                edge_exists = has_edge(G, v, u)::Bool
                if !edge_exists
                    c_map[n] -= 1
                end
            end
        end
    end
    # Remove v from G and the corresponding entry from c_map.
    N = nv(G)::Int
    c_map[v] = c_map[N]
    delete!(c_map, N)
    rem_vertex!(G, v)
end

"""
    cliqueness(G::LabeledGraph, v::Symbol)

Return the number of edges that need to be added to `G` in order to make the neighborhood of 
vertex labeled by the symbol `v` a clique.
"""
cliqueness(G::LabeledGraph, v::Symbol)::Int = cliqueness(G, get_vertex(G, v))

"""
    cliqueness(G::LabeledGraph, v::Integer)

Return the number of edges that need to be added to `G` in order to make the neighborhood of 
vertex `v` a clique.
"""
cliqueness(G::LabeledGraph, v::Integer)::Int = cliqueness(G.graph, v)

function cliqueness(G::lg.AbstractGraph, v::Integer)::Int
    neighborhood = lg.all_neighbors(G, v)::Array{Int64, 1}
    count = 0
    for i in 1:length(neighborhood)
        for j in i+1:length(neighborhood)
            vi = neighborhood[i]
            ui = neighborhood[j]
            if !lg.has_edge(G, ui, vi)::Bool
                count += 1
            end
        end
    end
    count
end



# **************************************************************************************** #
#                          Functions for creating various graphs
# **************************************************************************************** #

"""
    line_graph(G::LabeledGraph)

Return a LabeledGraph representing the line graph of the 'G'. 

The label for each each vertex of the line graph is created by concatenating the labels of 
the corresponding vertices in the LabeledGraph 'G'.
"""
function line_graph(G::LabeledGraph)
    G_edges = collect(edges(G))
    vertex_labels = [combine_labels(G.labels[e.src], G.labels[e.dst]) for e in G_edges]
    line_graph(G.graph; vertex_labels=vertex_labels)
end

"""
    line_graph(G::AbstractGraph;
               vertex_labels::Array{Symbol, 1}=Symbol[])

Return a LabeledGraph representing the line graph of the 'G'. 

The label for each each vertex of the line graph is created by 
concatenating the labels of the corresponding vertices in 'G'.

The symbols in the array `vertex_labels` are used as labels for the vertices of the returned
line graph. If `vertex_labels` is empty then labels are created by combining the indices of 
the corresponding vertices in 'G'.
"""
function line_graph(G::lg.AbstractGraph; 
                    vertex_labels::Array{Symbol, 1}=Symbol[])
    # Create a labeled graph LG whose vertices corresponding to the edges of G.
    G_edges = collect(lg.edges(G))
    if isempty(vertex_labels)
        vertex_labels = [combine_labels(e.src, e.dst) for e in G_edges]
    end
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


"""
    tree_from_tree_decompostion(td::Dict{Symbol, Any})

Returns a LabeledGraph representing the tree described by the tree decomposition in `td`.
"""
function tree_from_tree_decompostion(td::Dict{Symbol, Any})
    tree = LabeledGraph([Symbol("b_$i") for i in 1:td[:num_bags]])
    for (u, v) in td[:edges]
        add_edge!(tree, u, v)
    end
    tree
end


"""
    chordal_graph(G::LabeledGraph, π̄::Array{Symbol, 1})

Return a chordal graph built from 'G' using the elimination order 'π̄'.

The returned graph is created from 'G' by iterating over the vertices of 'G', according to 
the order 'π̄', and for each vertex, connecting all the neighbors that appear later in the 
order.
"""
function chordal_graph(G::LabeledGraph, π̄::Array{Symbol, 1})
    if !(Set(π̄) == Set(G.labels)) || !(length(π̄) == nv(G))
        error("π̄ must be an elimination order for G")
    end

    # Use G as a starting point for H and create dictionary to keep track of which vertices
    # in the elimination order haven't been considered yet. 
    H = deepcopy(G)
    higher_order = Dict{Symbol, Bool}(G.labels .=> true)

    # for each vertex v in the elimination order, connect the neighbors of v that appear
    # after v in the elimination order.
    for v in π̄
        higher_order[v] = false
        neighbors = all_neighbors(H, v)
        for i = 1:length(neighbors)-1
            for j = i+1:length(neighbors)
                u = H.labels[neighbors[i]]
                w = H.labels[neighbors[j]]
                if higher_order[u] && higher_order[w]
                    add_edge!(H, u, w)
                end
            end
        end
    end
    H
end

chordal_graph(G::LabeledGraph, π̄::Array{<:Integer, 1}) = chordal_graph(G, G.labels[π̄])