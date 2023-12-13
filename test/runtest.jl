module TestFireFrame


using FireFrame
using Test
using Documenter

DocMeta.setdocmeta!(FireFrame, :DocTestSetup, :(using FireFrame); recursive=true)

doctest(FireFrame)

end