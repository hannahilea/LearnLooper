using LearnLooper
using Documenter

makedocs(; modules=[LearnLooper],
    sitename="LearnLooper.jl",
    authors="hannahilea",
    pages=["API Documentation" => "index.md"],
    strict=true)

deploydocs(; repo="github.com/hannahilea/ExampleMonorepo.jl.git",
    push_preview=true,
    dirname="LearnLooper",
    tag_prefix="LearnLooper-",
    devbranch="main")
