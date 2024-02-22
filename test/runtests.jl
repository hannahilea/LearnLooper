using Test
using LearnLooper
using Aqua

@testset "LearnLooper" begin
    @testset "Aqua" begin
        Aqua.test_all(LearnLooper; ambiguities=false)
    end

    @testset "`compute_learnspan`" begin
        using LearnLooper: compute_learnspan
        contiguous_spans = [1:4, 5:8, 9:22]
        @test compute_learnspan(1, contiguous_spans; iteration_mode=:sequential) == 1:4
        @test compute_learnspan(2, contiguous_spans; iteration_mode=:sequential) == 5:8

        @test compute_learnspan(1, contiguous_spans; iteration_mode=:cumulative) == 1:4
        @test compute_learnspan(2, contiguous_spans; iteration_mode=:cumulative) ==
              [1:4, 5:8]

        noncontiguous_spans = [1:4, 9:22]
        @test compute_learnspan(1, noncontiguous_spans; iteration_mode=:cumulative) == 1:4
        @test compute_learnspan(2, noncontiguous_spans; iteration_mode=:cumulative) ==
              [1:4, 9:22]
    end

    @testset "`learnloop` from raw input" begin
        @test isnothing(learnloop(collect('a':'z'), [1:2, 3:4]; num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learnloop("A lone sentence is indexed by word", [1:2, 3:4]; num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learnloop(["A vector of phrases", "are indexed", "by phrase"], [1:2, 3:3]; num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learnloop(pi+0, [1:4, 5:8]; num_repetitions=2, iteration_mode=:cumulative))
    end

    @testset "`learnloop` from file" begin
        f = joinpath(pkgdir(LearnLooper), "README.md")
        @test isnothing(learnloop(read(f, String), [1:2, 3:4]; num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learnloop(readlines(f), [1:2, 5:5]; num_repetitions=2, iteration_mode=:cumulative))
    end

    @testset "`learnloop` from audio file" begin
        f = joinpath(pkgdir(LearnLooper), "README.md")
        @test isnothing(learnloop(read(f, String), [1:2, 3:4]; num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learnloop(readlines(f), [1:2, 5:5]; num_repetitions=2, iteration_mode=:cumulative))
    end
   
end
