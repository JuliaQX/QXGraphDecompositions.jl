@testset "Vertex elimination order tests" begin
    # A simple graph to test the min fill heuristic on.
    N = 10
    G = LabeledGraph(N)
    for i = 1:N
        for j = i+1:N
            add_edge!(G, i, j)
        end
    end

    # Check if the treewidth is correct, the order has the correct length and doesn't
    # contain repeated vertices. 
    treewidth_upperbound, elimination_order = min_fill(G)
    @test treewidth_upperbound == 9
    @test length(elimination_order) == N
    @test length(Set(elimination_order)) == N

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

    # Test the min fill heuristic on the square lattice graph.
    treewidth_upperbound, min_fill_order = min_fill(G)
    @test treewidth_upperbound == N-1
    @test length(min_fill_order) == N*N
    @test length(Set(min_fill_order)) == N*N

    # Test finding the treewidth of an elimination order.
    @test find_treewidth_from_order(G, min_fill_order) == N-1

    # Turn the first 4 vertices og the graph into a clique for test restricted mcs.
    n = 4
    for i = 1:n-1, j = i+1:n
        add_edge!(G, i, j)
    end

    # Get a tree decomposition of the square lattice graph and test converting it to an
    # elimination order.
    tree_decomp = flow_cutter(G, 15)
    td_order = order_from_tree_decomposition(tree_decomp)
    @test find_treewidth_from_order(G, td_order) == tree_decomp[:treewidth]
    @test length(td_order) == N*N
    @test length(Set(td_order)) == N*N

    # Select a set of vertices to form a clique and use restricted_mcs to get an
    # elimination order with the clique at the end. Check if the order has the correct 
    # treewidth.
    H = chordal_graph(G, td_order)
    C = [H.labels[i] for i = 1:n]
    modified_order = restricted_mcs(H, C)
    @test Set(C) == Set(modified_order[end-n+1:end])
    @test length(modified_order) == nv(H)
    @test length(Set(modified_order)) == length(modified_order)
    @test tree_decomp[:treewidth] == find_treewidth_from_order(G, modified_order)
end

@testset "QuickBB tests" begin
    # A simple graph to test quickbb on.
    N = 10
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end

    # check if the treewidth is correct, the peo has the correct length and doesn'tensor
    # contain repeated vertices. 
    peo, md = quickbb(G)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    peo, md = quickbb(G; time=5)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    peo, md = quickbb(G; order=:min_fill)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    peo, md = quickbb(G; order=:random)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    peo, md = quickbb(G; order=:min_fill, lb=true)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    peo, md = quickbb(G; time=5, order=:min_fill, lb=true)
    @test md[:treewidth] == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    G = LabeledGraph(G, [Symbol(:vert_, v) for v in 1:lg.nv(G)])
    peo, md = quickbb(G)
    @test md[:treewidth] == 9
    @test typeof(peo) == Array{Symbol, 1}
    @test Set(peo) == Set([Symbol(:vert_, v) for v in 1:nv(G)])
end