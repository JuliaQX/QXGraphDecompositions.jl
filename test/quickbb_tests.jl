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