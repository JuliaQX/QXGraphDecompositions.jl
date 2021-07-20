using FlowCutterPACE17_jll

import LightGraphs as lg

export flow_cutter
export min_fill, order_from_tree_decomposition, restricted_mcs, find_treewidth_from_order
export greedy_treewidth_deletion, direct_treewidth_score, build_clique_tree
export quickbb




# **************************************************************************************** #
#                                Tree Decompositions
# **************************************************************************************** #

"""
    flow_cutter(G::lg.AbstractGraph, time::Integer=10; seed::Integer=-1)

Run the flow cutter algorithm for `time` seconds to find a tree decomposition for the graph 
`G` with minimal treewidth.

The tree decomposition is returned in a dictionary with the following key value pairs:
- `:treewidth` => The treewidth of the tree decomposotion,  
- `:num_bags` => The number of bags in the tree decomposition,
- `:num_vertices` The number of vertices in `G`,
- `:b_n` => The n-th bag of the decomposition where n is an integer from 1 to the number of 
            bags in the decomposition. A bag is an array of vertices of `G`.
- `:edges` => An array of integer pairs indicating the edges of the tree decomposition.
- `:comments` => An array of comments created by flow cutter regarding heuristics used and if
                 it had enough time to find a decomposition.

The flow cutter algorithm and how it is used to find tree decompositions is described by
Michael Hamann and Ben Strasser in the following papers: 

Graph Bisection with Pareto Optimization - https://dl.acm.org/doi/10.1145/3173045
Computing Tree Decompositions with FlowCutter - https://arxiv.org/abs/1709.08949

# Keywords
- `seed::Integer=-1`: The seed used by flow cutter. Most be a non negative integer,
                      otherwise the seed is set by flow cutter.
"""
function flow_cutter(G::lg.AbstractGraph, time::Integer=10; seed::Integer=-1)
    # Create a temporary directory with the input and output files for flow cutter.
    out = Pipe()
    flow_cutter_dir = dirname(FlowCutterPACE17_jll.flow_cutter_pace17_path)
    mktempdir(flow_cutter_dir) do tdir
        graph_file = tdir * "/graph.gr"
        td_file = tdir * "/td.out"
        graph_to_gr(G, graph_file)

        # Call and run flow cutter for the specified duration of time.
        flow_cutter_pace17() do exe
            flow_cutter_cmd = [exe]
            seed >= 0 && append!(flow_cutter_cmd, ["-s", string(0)])
            flow_cutter_cmd = Cmd(flow_cutter_cmd)
            flow_cutter_proc = run(pipeline(graph_file, flow_cutter_cmd, td_file); wait=false)
            while !process_running(flow_cutter_proc) # Wait until process has started.
                sleep(1)
            end
            # TODO: Would be preferable to measure the execution time of the flow cutter
            # process here.
            sleep(time)
            kill(flow_cutter_proc)
        end
        flow_cutter_output = readlines(td_file)

        # Read the output of flow cutter into a dictionary to be returned to the user.
        td = Dict{Symbol, Any}()
        td[:edges] = Tuple{Int, Int}[]
        td[:comments] = String[]
        for line in flow_cutter_output
            words = split(line)
            if words[1] == "c"
                push!(td[:comments], line)
            elseif words[1] == "s"
                td[:num_bags] = parse(Int, words[3])
                td[:treewidth] = parse(Int, words[4]) - 1
                td[:num_vertices] = parse(Int, words[5])
            elseif words[1] == "b"
                td[Symbol("b_"*words[2])] = parse.(Int, words[3:end])
            elseif length(words) == 2
                push!(td[:edges], (parse(Int, words[1]), parse(Int, words[2])))
            end
        end
        return td
    end
end

flow_cutter(G::LabeledGraph, time::Integer=10; kwargs...) = flow_cutter(G.graph, time; kwargs...)


"""
    build_clique_tree(G, π̃)

Returns a tree decomposition for the graph `G` built from the given vertex 
elimination order `π`.

The algorithm used is by Schutski et al in Phys. Rev. A 102, 062614.
"""
function build_clique_tree(G, π̃)
    G = deepcopy(G)
    B = [] # bags
    T = lg.SimpleGraph() # tree

    orphan_bags = [] # Array to hold parentless vertices of T
    for i = 1:length(π̃)
        u = π̃[i]

        # Eliminate u from G: form a clique and remove u,
        # Take the clique formed by eliminating u as the next possible bag
        Nᵤ = [G.labels[v] for v in all_neighbors(G, u)]
        b = [u]; ib = length(B) + 1
        if !isempty(Nᵤ) b = [Nᵤ; u] end
        eliminate!(G, u)

        drop_bag = false
        # keep only maximal cliques
        for i in orphan_bags
            l = B[i]
            b∩l = intersect(b, l)
            if issubset(b, b∩l) # Set(b) == Set(intersect(b, l))
                b = l
                ib = i
                drop_bag = true
                break
            end
        end

        # add a new vetex to the tree for the next bag
        # and append it to the parentless vertices.
        if !drop_bag
            append!(B, [b])
            lg.add_vertex!(T)
            append!(orphan_bags, [ib])
        end

        # Check if the new bag is a parent of any of the
        # orphan vertices and update the list of orphans.
        for i in orphan_bags
            l = B[i]
            b∩l = intersect(b, l)
            if u in b∩l && !issubset(b, b∩l)
                orphan_bags = setdiff(orphan_bags, [i])
                # append!(B, [b])
                # add_vertex!(T)
                lg.add_edge!(T, i, ib)
            end
        end
    end
    B, T
end



# **************************************************************************************** #
#                               Vertex Elimination Orders
# **************************************************************************************** #

"""
    min_fill(G::AbstractGraph)

Returns the upper bound on the tree width of `G` found using the min-fill heuristic. An
elimination order with the returned treewidth is also returned.
"""
function min_fill(G::LabeledGraph)
    G = deepcopy(G)
    # Initialise variables to track the maximum degree of a vertex, the elimination order
    # and how close the neighbourhood of each vertex in G is to being a clique.
    max_degree = 0; ordering = Symbol[]
    cliqueness_map = Dict{Int, Int}(v => cliqueness(G,v) for v in vertices(G))

    # While vertices remain in 'G', remove a vertex whose neighbourhood is closest to
    # forming a clique and append it to the elimination order. Return the maximum degree
    # found as the upper bound on the tree width of 'G'.
    while nv(G) > 0
        v = argmin(cliqueness_map)
        max_degree = max(max_degree, degree(G, v))
        append!(ordering, [labels(G)[v]])
        eliminate!(G, v, cliqueness_map)
    end
    max_degree, ordering
end


"""
    order_from_tree_decomposition(td::Dict{Symbol, Any}; root::Symbol=:b_1)

Return a vertex elimination order with the same treewidth as the given tree decompositon.

The alogithm used to construct the vertex elimination order is described by Shutski et al in
the following paper https://doi.org/10.1103/PhysRevA.102.062614

# Keywords
- `root::Symbol=:b_1`: The node of the tree to take as the root. Must be a symbol of the
                       form `:b_n` where `n` is an integer between 1 and the number of bags
                       in the tree decomposition.
"""
function order_from_tree_decomposition(td::Dict{Symbol, Any}; root::Symbol=:b_1)
    # Initialise the elimination order and an array containing the names of the bags in the
    # given tree decomposition. Also, create a labeled graph representing the tree in the
    # tree decomposition.
    elimination_order = Int[]
    B = [Symbol("b_$b") for b in 1:td[:num_bags]]
    tree = tree_from_tree_decompostion(td)
    @assert root in B "The root should be one of the bags in the tree decomposition"

    # While the tree has leaf nodes, remove leaves from the tree and append the appropriate
    # bags of vertices to the elimination order.
    while nv(tree) > 1
        # Let 'b' be a leaf node of the tree. If none exist then let it be the root node.
        b = root
        for bi in B
            if (length(all_neighbors(tree, bi)) == 1) && !(bi == root)
                b = bi
                break
            end
        end

        # Let 'p' be the parent node of 'b' and append to the elimination order the vertices 
        # that are in the bag associated wit 'b' but not in the bag associated with 'p'.
        p = labels(tree)[all_neighbors(tree, b)[1]]
        m = setdiff(td[b], td[p])
        append!(elimination_order, m)

        # Remove the leaf node from the tree.
        if !(b == root)
            setdiff!(B, [b])
            rem_vertex!(tree, b)
        end
    end
    append!(elimination_order, td[root])
end


"""
    restricted_mcs(H::LabeledGraph, C::Array{Symbol, 1})

Return an elimination order for the chordal graph 'H' with the vertices in 'C' appearing at 
the end.

If the chordal graph `H` was created from an elimination order π for a graph `G`, the 
returned elimination order for `H` will have a treewidth equal to that of π if `C` is a
clique in `H`.

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


"""
    find_treewidth_from_order(G::LabeledGraph, π̄::Array{Symbol, 1})

Return the treewidth of `G` with respect to the elimination order `π̄`.
"""
function find_treewidth_from_order(G::LabeledGraph, π̄::Array{Symbol, 1})
    G = deepcopy(G)
    τ = 0
    for v_label in π̄
        v = get_vertex(G, v_label)
        τ = max(τ, degree(G, v))
        eliminate!(G, v)
    end
    τ
end

find_treewidth_from_order(G::LabeledGraph, π̄::Array{<:Integer, 1}) = begin
    π̄ = [G.labels[i] for i in π̄]
    find_treewidth_from_order(G, π̄)
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

The intermediate elimination orders and corresponding treewidths of the intermediate graphs
are also returned if an elimination order for G is provided.

The algorithm is described by Schutski et al in Phys. Rev. A 102, 062614.

# Keywords
- `score_function::Symbol=:degree`: function to maximise when selecting vertices to remove.
                                    (:degree, :direct_treewidth)
- `elim_order::Array{Symbol, 1}=Symbol[]`: The elimination order for G to be used by 
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

    if score_function in [:direct_treewidth, :tree_trimming]
        if !(length(elim_order) == nv(G))
            error("The chosen score function requires an elimination order.")
        end
    end

    μ = []; f = SCORES[score_function]
    G̃ = deepcopy(G); π̃ = copy(elim_order)
    π̄s = Array{Array{Symbol, 1}, 1}(undef, m)
    τs = Array{Int, 1}(undef, m)

    # Remove m vertices from G̃ which maximise the chosen score function.
    for j = 1:m
        u = f(G̃, π̃)
        u_label = G̃.labels[u]
        rem_vertex!(G̃, u)
        append!(μ, [u_label])

        # Record the modified elimination ordering for the new graph.
        # TODO: add an option to recalculate an elimination ordering for G
        π̃ = setdiff(π̃, [u_label]); π̄s[j] = π̃
        if length(π̃) == nv(G̃)
            τs[j] = find_treewidth_from_order(G̃, π̃)
        end
    end

    # If an elimination order was provided, return the modified elimination orders for the 
    # intermediate graphs G̃ and the corresponding treewidths with respect to the modified 
    # elimination orders.
    if length(π̃) == nv(G̃)
        return G̃, μ, π̄s, τs
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
    tree_trimming(G, π̃)

Returns a vertex of `G` which can be removed to reduce its treewidth. The selected
vertex is chosen based on a tree decompostion built from the vertex elimination
order `π̃`.

Implements the tree trimming algorithm described by Schutski et al 
in Phys. Rev. A 102, 062614.
"""
function tree_trimming(G, π̃)
    # Get a tree decomposition for G base on π̃.
    B, T = build_clique_tree(G, π̃)

    # Find the largest bag in B. If multiple maximal bags
    # are found, consider their union.
    largest_bag_size = maximum(length.(B))
    bₘ = [b for b in B if length(b) == largest_bag_size]
    bₘ = reduce(union, bₘ)

    # For each node in bₘ find its weighted subtree Sᵤ.
    S = []
    weights = []
    for u in bₘ
        Sᵤ = [b for b in B if u in b]
        total_weightᵤ = sum([length(b) for b in Sᵤ])
        append!(S, [Sᵤ])
        append!(weights, [total_weightᵤ])
    end

    # Select the Sᵤ with largest length, or largest weight in case of
    # equal length. Return the corresponding vertex u.
    largest_length = maximum(length.(S))
    largest_S = [i for (i, s) in enumerate(S) if length(s) == largest_length]
    i = argmax(weights[largest_S])
    u = bₘ[largest_S[i]]
    get_vertex(G, u)
end


# A dictionary of score functions for the greedy_treewidth_deletion algorithm.
SCORES = Dict()
SCORES[:degree] = (G, π) -> argmax(degree(G))
SCORES[:direct_treewidth] = (G, π) -> argmax(direct_treewidth_score(G, π))
SCORES[:tree_trimming] = tree_trimming



# *************************************************************************************** #
#                       Functions to use Gogate's QuickBB binary
# *************************************************************************************** #

"""
    quickbb(G::lg.AbstractGraph; 
            time::Integer=0, 
            order::Symbol=:_, 
            verbose::Bool=false )::Tuple{Int, Array{Int, 1}}

Call Gogate's QuickBB binary on the provided graph and return the resulting perfect 
elimination ordering. 

A dictionary containing metadata for the elimination order is also returned. Metadata
includes: 
- `:treewidth` of the elimination order,  
- `:time` taken by quickbb to find the order,
- `:lowerbound` for the treewidth computed by quickbb,
- `:is_optimal` a boolean indicating if the order as optiaml treewidth.

The QuickBB algorithm is described in arXiv:1207.4109v1

# Keywords
- `time::Integer=0`: the number of second to run the quickbb binary for.
- `order::Symbol=:_`: the branching order to be used by quickbb (:random or :min_fill).
- `lb::Bool=false`: set if a lowerbound for the treewidth should be computed.
- `verbose::Bool=false`: set to true to print quickbb stdout and stderr output.
- `proc_id::Integer=0`: used to create uniques names of files for different processes.
"""
function quickbb(G::lg.AbstractGraph; 
                time::Integer=0, 
                order::Symbol=:_, 
                lb::Bool=false,
                verbose::Bool=false,
                proc_id::Integer=0)

    # Assuming Gogate's binary can be run using docker in quickbb/ located in same
    # directory as the current file.
    qbb_dir = dirname(@__FILE__) * "/quickbb"
    work_dir = pwd()

    try
        cd(qbb_dir)
        # Write the graph G to a CNF file for the quickbb binary and clear any output from
        # previous runs.
        mktempdir(qbb_dir) do tdir
            tdir = basename(tdir)
            qbb_out = tdir * "/qbb_$(proc_id).out" 
            graph_cnf = tdir * "/graph_$(proc_id).cnf"
            graph_to_cnf(G, graph_cnf)

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
                if lb
                    append!(quickbb_cmd, ["--lb"])
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
                if lb
                    append!(quickbb_cmd, ["--lb"])
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
            metadata = Dict{Symbol, Any}()
            lines = readlines(qbb_out)
            metadata[:treewidth] = parse(Int, split(lines[1])[end])
            if lb
                perfect_elimination_order = parse.(Int, split(lines[end-1]))
                metadata[:lowerbound] = parse(Int, split(lines[2])[end])
                metadata[:time] = parse(Float64, split(lines[3])[end])
                metadata[:is_optimal] = length(split(lines[4])) == 4
            else
                perfect_elimination_order = parse.(Int, split(lines[end]))
                metadata[:time] = parse(Float64, split(lines[2])[end])
                metadata[:is_optimal] = length(split(lines[3])) == 4
            end
            return perfect_elimination_order, metadata
        end

    finally
        # Clean up before returning results.
        cd(work_dir)
    end
end

function quickbb(G::LabeledGraph; 
                time::Integer=0, 
                order::Symbol=:_, 
                lb::Bool=false,
                verbose::Bool=false,
                proc_id::Integer=0)

    peo, metadata = quickbb(G.graph; time=time, order=order, lb=lb, 
                            verbose=verbose, proc_id=proc_id)

    # Convert the perfect elimination order to an array of vertex labels before returning
    [G.labels[v] for v in peo], metadata
end