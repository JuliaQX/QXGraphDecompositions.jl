@testset "Tree decomposition tests" begin
    # A simple graph to test flow cutter on.
    N = 10
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end

    # Check if the treewidth and number of bags is correct and check that the tree 
    # decomposition has no edges.
    tree_decomp = flow_cutter(G, 30; seed=42)
    @test tree_decomp[:treewidth] == 9
    @test tree_decomp[:num_bags] == 1
    @test length(tree_decomp[:edges]) == 0

    # A simple graph with two disconnected cliques to test flow cutter on.
    N = 10; n = 5
    G = lg.SimpleGraph(N+n)
    # Clique 1
    for i = 1:N-1
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end
    # Clique 2
    for i = N+1:N+n-1
        for j = i+1:N+n
            lg.add_edge!(G, i, j)
        end
    end

    # Check if the treewidth, number of bags and number of edges is correct.
    tree_decomp = flow_cutter(G, 30; seed=42)
    @test tree_decomp[:treewidth] == N-1
    @test tree_decomp[:num_bags] == 2
    @test tree_decomp[:num_vertices] == N + n
    @test length(tree_decomp[:edges]) == 1

    # Test constructing a tree decomposition from an elimination order
    # A square lattice graph to test the min fill heuristic and conversion of a tree 
    # decomposition to an elimination order.
    N = 5
    G = LabeledGraph(N*N)
    for i = 1:N-1
        for j = 1:N
            add_edge!(G, i + N*(j-1), i + N*(j-1) + 1)
            add_edge!(G, i + N*(j-1), i + N*(j-1) + N)
        end
    end
    treewidth_upperbound, min_fill_order = min_fill(G)
    B, T = build_clique_tree(G, min_fill_order)
    @test length(B) == lg.nv(T)
    @test treewidth_upperbound == maximum(length.(B)) - 1
end