@testset "Treewidth deletion tests" begin
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

    G = LabeledGraph(G)
    tw, π̄ = quickbb(G)

    # check if the treewidth is reduced by the correct amount and number of vertices removed
    # is correct. 
    Ḡ, μ = greedy_treewidth_deletion(G, 5)
    τ, peo = quickbb(Ḡ)
    @test τ == tw - 5
    @test nv(Ḡ) == 15
    @test length(μ) == 5

    Ḡ, μ, π̃, τ = greedy_treewidth_deletion(G, 5; 
                                           score_function=:direct_treewidth, elim_order=π̄)
    @test τ == tw - 5
    @test nv(Ḡ) == 15
    @test length(μ) == 5
    @test length(π̃) == nv(Ḡ)
end