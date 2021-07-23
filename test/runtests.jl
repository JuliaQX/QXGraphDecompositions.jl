using QXGraphDecompositions
using Test

import LightGraphs; lg = LightGraphs

include("LabeledGraph_tests.jl")
include("elimination_order_tests.jl")
include("tree_decomposition_tests.jl")
include("treewidth_deletion_tests.jl")
