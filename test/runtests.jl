using QXGraphDecompositions
using Test

import LightGraphs; lg = LightGraphs

include("LabeledGraph_tests.jl")
include("elimination_order_tests.jl")
include("flow_cutter_tests.jl")
include("treewidth_deletion_tests.jl")
