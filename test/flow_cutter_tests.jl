@testset "Flow Cutter tests" begin
    # A simple graph to test flow cutter on.
    N = 10
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end

    # Check if the treewidth, number of bags and number of vertices is correct and check
    # that the tree decomposition has no edges.
    tree_decomp = flow_cutter(G; time=10)
    @test tree_decomp[:treewidth] == 9
    @test tree_decomp[:num_bags] == 1
    @test tree_decomp[:num_vertices] == 10
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

    # Check if the treewidth, number of bags and number of vertices is correct and check
    # that the tree decomposition has no edges.
    tree_decomp = flow_cutter(G; time=10)
    @test tree_decomp[:treewidth] == N-1
    @test tree_decomp[:num_bags] == 2
    @test length(tree_decomp[:edges]) == 1
end