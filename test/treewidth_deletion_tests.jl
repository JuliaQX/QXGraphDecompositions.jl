@testset "Treewidth deletion tests" begin
    # A simple graph to test on.
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
    tw, π̄ = min_fill(G)

    # check if the treewidth is reduced by the correct amount and number of vertices removed
    # is correct.
    Ḡ, μ = greedy_treewidth_deletion(G, 5; score_function=:degree)
    modified_tw, modifued_π̄ = min_fill(Ḡ)
    @test modified_tw == tw - 5
    @test nv(Ḡ) == 15
    @test length(μ) == 5

    Ḡ, μ, π̃s, τs = greedy_treewidth_deletion(G, 5; 
                                             score_function=:direct_treewidth, elim_order=π̄)
    @test τs == [tw-1, tw-2, tw-3, tw-4, tw-5]
    @test nv(Ḡ) == 15
    @test length(μ) == 5
    @test length(π̃s[end]) == nv(Ḡ)

    # Test the tree trimming method for selecting vertices to delete.
    Ḡ, μ, π̃s, τs = greedy_treewidth_deletion(G, 5; elim_order=π̄)
    @test τs == [tw-1, tw-2, tw-3, tw-4, tw-5]
    @test nv(Ḡ) == 15
    @test length(μ) == 5
    @test length(π̃s[end]) == nv(Ḡ)
end