import LightGraphs; lg = LightGraphs

export quickbb

# *************************************************************************************** #
#                         Functions to use Gogate's QuickBB binary
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

# Arguments
- `time::Integer=0`: the number of second to run the quickbb binary for.
- `order::Symbol=:_`: the branching order to be used by quickbb.
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