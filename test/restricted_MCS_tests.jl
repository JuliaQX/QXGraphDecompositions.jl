@testset "Restricted max cardinality search tests" begin
    # A simple graph to test quickbb on.
    N = 10
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end
    for i = 1:10
        lg.add_vertex!(G)
        lg.add_edge!(G, N+i-1, N+i)
    end

    # Convert G to a labeled graph and find a peo for it.
    G = LabeledGraph(G)
    tw, π̄ = quickbb(G)

    # Create a chordal graph with respect to the peo
    # Check if it has some of the correct properties.
    H = build_chordal_graph(G, π̄)
    @test ne(H) >= ne(G)
    @test H.labels == G.labels
    @test tw == find_treewidth_from_order(H, π̄)

    # select a set of vertices to form a clique and use restricted_mcs to get_vertex
    # a peo with the clique at the end. Check if the new peo has the correct treewidth.
    n = 4
    C = [H.labels[i] for i = 1:n]
    modified_π̄ = restricted_mcs(H, C)
    @test Set(C) == Set(modified_π̄[end-n+1:end])
    @test length(modified_π̄) == nv(H)
    @test length(Set(modified_π̄)) == length(modified_π̄)
    @test tw == find_treewidth_from_order(G, modified_π̄)
end