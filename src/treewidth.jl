import LightGraphs; lg = LightGraphs

export quickbb
export greedy_treewidth_deletion

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
    qbb_dir = @__FILE__
    qbb_dir = qbb_dir[1:end-12] * "quickbb"
    work_dir = pwd()
    cd(qbb_dir)

    # Write the graph G to a CNF file for the quickbb binary and clear any output from
    # previous runs. 
    qbb_out = "qbb_$(proc_id).out"; graph_cnf = "graph_$(proc_id).cnf"
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

    # Clean up before returning results.
    rm(qbb_out; force=true)
    rm(graph_cnf; force=true)
    cd(work_dir)
    treewidth, perfect_elimination_order
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