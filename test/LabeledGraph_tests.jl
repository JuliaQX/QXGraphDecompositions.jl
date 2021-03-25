@testset "LabeledGraph tests" begin
    # A simple graph to test LabeledGraph functions on.
    N = 6
    G = lg.SimpleGraph(N)
    for i = 1:N
        for j = i+1:N
            lg.add_edge!(G, i, j)
        end
    end
    vertex_labels = [Symbol(:vertex_, n) for n in lg.vertices(G)]
    Labeled_G = LabeledGraph(G, vertex_labels)

    # Test functions for inspecting a labeled graph.
    @test nv(Labeled_G) == lg.nv(G)
    @test ne(Labeled_G) == lg.ne(G)
    @test labels(Labeled_G) == Labeled_G.labels
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
    @assert has_edge(Labeled_G, u, v) == false
    eliminate!(Labeled_G, 1)
    u = get_vertex(Labeled_G, :vertex_8); v = get_vertex(Labeled_G, :vertex_7)
    @test has_edge(Labeled_G, u, v)
    @test get_vertex(Labeled_G, :vertex_6) === nothing

    # Check if line graph of G has the correct number of vertices and edges.
    Labeled_G = LabeledGraph(G)
    LG = line_graph(Labeled_G)
    @test nv(LG) == N*(N-1)/2
    @test ne(LG) == (N-2)*N*(N-1)/2

    # Test some of the LabeledGraph constructors.
    G = LabeledGraph(5)
    @test nv(G) == 5
    @test length(G.labels) == 5

    G = LabeledGraph([Symbol(2*i) for i = 1:5])
    @test nv(G) == 5
    @test length(G.labels) == 5
    @test labels(G) == [Symbol(2*i) for i = 1:5]

    add_edge!(G, 1, 2); add_edge!(G, 1, 3); add_edge!(G, 1, 4)
    @test cliqueness(G, Symbol(2)) == 3

    # A square lattice graph to test building a chordal graph with.
    N = 5
    G = LabeledGraph(N*N)
    for i = 1:N-1
        for j = 1:N-1
            add_edge!(G, i + N*(j-1), i + N*(j-1) + 1)
            add_edge!(G, i + N*(j-1), i + N*(j-1) + N)
        end
    end
    treewidth_upperbound, min_fill_order = min_fill_ub(G)

    # Create a chordal graph with respect to the order found and check if it has some of the 
    # correct properties.
    H = chordal_graph(G, min_fill_order)
    @test ne(H) > ne(G) # H has more edges than G.
    @test H.labels == G.labels # H has the same labels as G.
    @test treewidth_upperbound == find_treewidth_from_order(H, min_fill_order) # Same tw.
end