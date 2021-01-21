@testset "LabeledGraph tests" begin
    # A simple graph to test LabeledGraph functions on.
    N = 6
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end

    labels = [Symbol(:vertex_, n) for n in lg.vertices(G)]
    Labeled_G = LabeledGraph(G, labels)

    @test nv(Labeled_G) == lg.nv(G)
    @test ne(Labeled_G) == lg.ne(G)
    @test get_vertex(Labeled_G, :vertex_3) == 3

    # Check if vertices are removed correctly by rem_vertex!
    rem_vertex!(Labeled_G, 1)
    rem_vertex!(Labeled_G, :vertex_3)
    @test nv(Labeled_G) == N-2
    @test Labeled_G.labels == [Symbol(:vertex_, v) for v in [6, 2, 5, 4]]

    # Check if add_vertex! works correctly.
    add_vertex!(Labeled_G, :vertex_7)
    @test nv(Labeled_G) == 5
    @test Labeled_G.labels[5] == :vertex_7

    # Check if has_edge, add_edge! and rem_edge! work correctly.
    @test has_edge(Labeled_G, 1, 5) == false
    add_edge!(Labeled_G, 1, 5)
    @test has_edge(Labeled_G, 1, 5) == true
    rem_edge!(Labeled_G, 1, 5)
    @test has_edge(Labeled_G, 1, 5) == false

    # Check degree function.
    @test degree(Labeled_G) == [3, 3, 3, 3, 0]
    @test degree(Labeled_G, 2) == 3
    @test degree(Labeled_G, [1, 3, 5]) == [3, 3, 0]
    @test degree(Labeled_G, [:vertex_6, :vertex_5, :vertex_7]) == [3, 3, 0]

    # Check if eliminate! function connects removes vertex and connects its neighbors.
    add_vertex!(Labeled_G, :vertex_8)
    add_edge!(Labeled_G, 1, 5)
    add_edge!(Labeled_G, 1, 6)
    u = get_vertex(Labeled_G, :vertex_8); v = get_vertex(Labeled_G, :vertex_7)
    @test has_edge(Labeled_G, u, v) == false
    eliminate!(Labeled_G, 1)
    u = get_vertex(Labeled_G, :vertex_8); v = get_vertex(Labeled_G, :vertex_7)
    @test has_edge(Labeled_G, u, v)
    @test get_vertex(Labeled_G, :vertex_6) === nothing

    # Check if line graph of G has the correct number of vertices and edges.
    LG = line_graph(G)
    @test nv(LG) == N*(N-1)/2
    @test ne(LG) == (N-2)*N*(N-1)/2

    Labeled_G = LabeledGraph(G)
    LG = line_graph(Labeled_G)
    @test nv(LG) == N*(N-1)/2
    @test ne(LG) == (N-2)*N*(N-1)/2
end