import LightGraphs; lg = LightGraphs

export quickbb
export greedy_treewidth_deletion, find_treewidth_from_order
export build_chordal_graph, restricted_mcs

# *************************************************************************************** #
#                       Functions to use Gogate's QuickBB binary
# *************************************************************************************** #

"""
    graph_to_cnf(G::lg.AbstractGraph, filename::String)

Write the provided graph to a cnf file for Gogate's QuickBB binary.
"""
function graph_to_cnf(G::lg.AbstractGraph, filename::String)
    open(filename, "w") do io
        write(io, "p cnf $(lg.nv(G)) $(lg.ne(G))\n")
        for e in lg.edges(G)
            write(io, "$(e.src) $(e.dst) 0\n")
        end
    end
end

"""
    quickbb(G::lg.AbstractGraph; 
            time::Integer=0, 
            order::Symbol=:_, 
            verbose::Bool=false )::Tuple{Int, Array{Int, 1}}

Call Gogate's QuickBB binary on the provided graph and return the resulting treewidth and 
perfect elimination ordering. 

The QuickBB algorithm is described in arXiv:1207.4109v1

# Keywords
- `time::Integer=0`: the number of second to run the quickbb binary for.
- `order::Symbol=:_`: the branching order to be used by quickbb (:random or :min_fill).
- `verbose::Bool=false`: set to true to print quickbb stdout and stderr output.
- `proc_id::Integer=0`: used to create uniques names of files for different processes.
"""
function quickbb(G::lg.AbstractGraph; 
                time::Integer=0, 
                order::Symbol=:_, 
                verbose::Bool=false,
                proc_id::Integer=0)::Tuple{Int, Array{Int, 1}}

    # Assuming Gogate's binary can be run using docker in quickbb/ located in same
    # directory as the current file.
    qbb_dir = dirname(@__FILE__) * "/quickbb"
    work_dir = pwd()
    qbb_out = "qbb_$(proc_id).out"; graph_cnf = "graph_$(proc_id).cnf"

    try
        # Write the graph G to a CNF file for the quickbb binary and clear any output from
        # previous runs. 
        cd(qbb_dir)
        graph_to_cnf(G, graph_cnf)
        rm(qbb_out; force=true)

        # Write the appropriate command to call quickbb with the specified options.
        if Sys.isapple()
            quickbb_cmd = ["docker", "run", "-v", "$(qbb_dir):/app", "myquickbb"]
            if order == :random
                append!(quickbb_cmd, ["--random-ordering"])
            elseif order == :min_fill
                append!(quickbb_cmd, ["--min-fill-ordering"])
            end
            if time > 0
                append!(quickbb_cmd, ["--time", string(time)])
            end
            append!(quickbb_cmd, ["--outfile", qbb_out, "--cnffile", graph_cnf])
            quickbb_cmd = Cmd(quickbb_cmd)

            # run the quickbb command.
            if verbose
                run(quickbb_cmd)
            else
                out = Pipe()
                run(pipeline(quickbb_cmd, stdout=out, stderr=out))
            end

        elseif Sys.islinux()
            quickbb_cmd = ["./quickbb_64"]
            if order == :random
                append!(quickbb_cmd, ["--random-ordering"])
            elseif order == :min_fill
                append!(quickbb_cmd, ["--min-fill-ordering"])
            end
            if time > 0
                append!(quickbb_cmd, ["--time", string(time)])
            end
            append!(quickbb_cmd, ["--outfile", qbb_out, "--cnffile", graph_cnf])
            quickbb_cmd = Cmd(quickbb_cmd)

            # run the quickbb command.
            if verbose
                run(quickbb_cmd)
            else
                out = Pipe()
                run(pipeline(quickbb_cmd, stdout=out, stderr=out))
            end
        end

        # Read in the output from quickbb.
        lines = readlines(qbb_out)
        treewidth = parse(Int, split(lines[1])[end])
        perfect_elimination_order = parse.(Int, split(lines[end]))
        return treewidth, perfect_elimination_order

    finally
        # Clean up before returning results.
        rm(qbb_out; force=true)
        rm(graph_cnf; force=true)
        cd(work_dir)
    end
end

function quickbb(G::LabeledGraph; 
                time::Integer=0, 
                order::Symbol=:_, 
                verbose::Bool=false,
                proc_id::Integer=0)::Tuple{Int, Array{Symbol, 1}}

    treewidth, peo = quickbb(G.graph; time=time, order=order, 
                             verbose=verbose, proc_id=proc_id)

    # Convert the perfect elimination order to an array of vertex labels before returning
    treewidth, [G.labels[v] for v in peo]
end


# **************************************************************************************** #
#                      Schutski's greedy method for automatic slicing
# **************************************************************************************** #

"""
    greedy_treewidth_deletion(G::LabeledGraph, m::Int=4;
                              score_function::Symbol=:degree, 
                              π::Array{Symbol, 1}=[])

Greedily remove vertices from G with respect to minimising the chosen score function.
Return the reduced graph and an array of vertices which were removed.

A reduced elimination order and the treewidth of the reduced graph, with respect to that
elimination order, is also returned if an elimination order for G is provided.

The algorithm is described by Schutski et al in Phys. Rev. A 102, 062614.

# Keywords
- `score_function::Symbol=:degree`: function to maximise when selecting vertices to remove.
                                    (:degree, :direct_treewidth)
- `elim_order:Array{Symbol, 1}=Symbol[]`: The elimination order for G to be used by 
                                          direct_treewidth score function.
"""
function greedy_treewidth_deletion(G::LabeledGraph, m::Int=4;
                                   score_function::Symbol=:degree, 
                                   elim_order::Array{Symbol, 1}=Symbol[])
    # Check if keyword arguments are suitable.
    if !(score_function in keys(SCORES)) 
        scores = collect(keys(SCORES))
        error("The keyword argument score_function must be one of the following: $scores")
    end

    if score_function == :direct_treewidth
        if !(length(elim_order) == nv(G))
            error("The direct treewidth score requires an elimination order.")
        end
    end

    μ = []; f = SCORES[score_function]
    G̃ = deepcopy(G); π̃ = copy(elim_order)

    # Remove m vertices from G̃ which maximise the chosen score function.
    for j = 1:m
        u = argmax(f(G̃, π̃))
        u_label = G̃.labels[u]
        rem_vertex!(G̃, u)
        setdiff!(π̃, [u_label])
        append!(μ, [u_label])
    end

    # If an elimination order was provided, return the modified elimination order for G̃
    # and the treewidth of G̃ with respect to the modified elimination order.
    if length(π̃) == nv(G̃)
        τ = find_treewidth_from_order(G̃, π̃)
        return G̃, μ, π̃, τ
    else
        return G̃, μ
    end
end

"""
    direct_treewidth_score(G::LabeledGraph, π::Array{Symbol, 1})

Return an array of integers, one for each vertex in G, indicating the change in treewidth of
G, with respect to π, if that vertex is removed.
"""
function direct_treewidth_score(G::LabeledGraph, π̄::Array{Symbol, 1})
    τ = find_treewidth_from_order(G, π̄)
    Δ = Array{Int, 1}(undef, nv(G))

    for u in vertices(G)
        G̃ = deepcopy(G)
        rem_vertex!(G̃, u)
        π̃ = setdiff(π̄, [G.labels[u]])

        Δ[u] = τ - find_treewidth_from_order(G̃, π̃)
    end

    Δ
end

"""
    find_treewidth_from_order(G::LabeledGraph, π̄::Array{Symbol, 1})

Return the treewidth of G with respect to the elimination order π̄.
"""
function find_treewidth_from_order(G::LabeledGraph, π̄::Array{Symbol, 1})
    G = deepcopy(G)
    τ = 1
    for v_label in π̄
        v = get_vertex(G, v_label)
        τ = max(τ, degree(G, v))
        eliminate!(G, v)
    end
    τ
end

# A dictionary of score functions for the greedy_treewidth_deletion algorithm.
SCORES = Dict()
SCORES[:degree] = (G, π) -> degree(G)
SCORES[:direct_treewidth] = direct_treewidth_score


# **************************************************************************************** #
#                     Functions for Schutski's partial contraction method
# **************************************************************************************** #

"""
    build_chordal_graph(G::LabeledGraph, π̄::Array{Symbol, 1})

Return a chordal graph built from 'G' using the elimination order 'π̄'.

The returned graph is created from 'G' by iterating of the vertices of 'G', according to the
order 'π̄', and for each vertex, connecting all the neighbors that appear later in the order.
"""
function build_chordal_graph(G::LabeledGraph, π̄::Array{Symbol, 1})
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
            for j = i:length(neighbors)
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


"""
    restricted_mcs(H::LabeledGraph, C::Array{Symbol, 1})

Return an elimination order for 'H' with the vertices in 'C' appearing at the end.

The algorithm is described by Shutski et al in https://arxiv.org/abs/1911.12242
"""
function restricted_mcs(H::LabeledGraph, C::Array{Symbol, 1})
    C = copy(C)
    cardinality = Dict{Symbol, Int}(H.labels .=> 0)
    is_not_in_π̄ = Dict{Symbol, Bool}(H.labels .=> true)
    π̄ = Array{Symbol, 1}(undef, nv(H))

    # Create the elimination order starting at the end and working back to the beginning.
    for i = length(π̄):-1:1
        # Select a vertex to appear next in the elimination order.
        if length(C) > 0
            v = pop!(C)
        else
            v = argmax(cardinality)
        end

        # Add the vertex to the elimination order, and remove it from the cardinality map.
        delete!(cardinality, v)
        π̄[i] = v
        is_not_in_π̄[v] = false

        # Update the cardinality of the remaining vertices.
        for w_ind in all_neighbors(H, v)
            w = H.labels[w_ind]
            if is_not_in_π̄[w]
                cardinality[w] += 1
            end
        end
    end
    π̄
end