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
    tw, peo = quickbb(G)
    @test tw == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    tw, peo = quickbb(G; time=5)
    @test tw == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    tw, peo = quickbb(G; order=:min_fill)
    @test tw == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    tw, peo = quickbb(G; order=:random)
    @test tw == 9
    @test length(peo) == N
    @test length(Set(peo)) == N

    G = LabeledGraph(G, [Symbol(:vert_, v) for v in 1:lg.nv(G)])
    tw, peo = quickbb(G)
    @test typeof(peo) == Array{Symbol, 1}
    @test Set(peo) == Set([Symbol(:vert_, v) for v in 1:nv(G)])
end