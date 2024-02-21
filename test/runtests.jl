using Test
using LearnLooper
using Aqua

@testset "LearnLooper" begin
    @testset "Aqua" begin
        Aqua.test_all(LearnLooper; ambiguities=false)
    end

    @testset "Entrypoints" begin
        isnothing(learn_demo())
    end

    @testset "`get_learnspan`" begin
        using LearnLooper: get_learnspan
        contiguous_spans = [1:4, 5:8, 9:22]
        @test get_learnspan(1, contiguous_spans; iteration_mode=:sequential) == 1:4
        @test get_learnspan(2, contiguous_spans; iteration_mode=:sequential) == 5:8

        @test get_learnspan(1, contiguous_spans; iteration_mode=:cumulative) == 1:4
        @test get_learnspan(2, contiguous_spans; iteration_mode=:cumulative) == [1:4, 5:8]

        noncontiguous_spans = [1:4, 9:22]
        @test get_learnspan(1, noncontiguous_spans; iteration_mode=:cumulative) == 1:4
        @test get_learnspan(2, noncontiguous_spans; iteration_mode=:cumulative) ==
              [1:4, 9:22]
    end
end
