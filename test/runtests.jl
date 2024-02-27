using Test
using LearnLooper
using Aqua

@testset "LearnLooper" begin
    @testset "Aqua" begin
        Aqua.test_all(LearnLooper; ambiguities=false)
    end

    @testset "`collect_span`" begin
        using LearnLooper: collect_span
        contiguous_spans = [1:4, 5:8, 9:22]
        @test collect_span(1, contiguous_spans; iteration_mode=:sequential) == 1:4
        @test collect_span(2, contiguous_spans; iteration_mode=:sequential) == 5:8

        @test collect_span(1, contiguous_spans; iteration_mode=:cumulative) == 1:4
        @test collect_span(2, contiguous_spans; iteration_mode=:cumulative) ==
              [1:4, 5:8]

        noncontiguous_spans = [1:4, 9:22]
        @test collect_span(1, noncontiguous_spans; iteration_mode=:cumulative) == 1:4
        @test collect_span(2, noncontiguous_spans; iteration_mode=:cumulative) ==
              [1:4, 9:22]
    end

    @testset "`learn_loop` from raw input" begin
        @test isnothing(learn_loop(collect('a':'z'), [1:2, 3:4]; num_repetitions=2,
                                   iteration_mode=:cumulative))
        @test isnothing(learn_loop("A lone sentence is indexed by word", [1:2, 3:4];
                                   num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learn_loop(["A vector of phrases", "are indexed", "by phrase"],
                                   [1:2, 3:3]; num_repetitions=2,
                                   iteration_mode=:cumulative))
        @test isnothing(learn_loop(pi + 0, [1:4, 5:8]; num_repetitions=2,
                                   iteration_mode=:cumulative))
    end

    @testset "`learn_loop` from file" begin
        f = joinpath(pkgdir(LearnLooper), "README.md")
        @test isnothing(learn_loop(read(f, String), [1:2, 3:4]; num_repetitions=2,
                                   iteration_mode=:cumulative))
        @test isnothing(learn_loop(readlines(f), [1:2, 5:5]; num_repetitions=2,
                                   iteration_mode=:cumulative))
    end

    @testset "`learn_loop` from audio file" begin
        using LearnLooper: LEHRER_DEMO_SONG, index_for_sec_spans

        # Temporary until we use TimeSpans:
        spans = [(0, 1.2), (4, 8)]
        @test index_for_sec_spans(spans, 1) == [0:1, 4:8]
        @test isnothing(learn_loop(LEHRER_DEMO_SONG, [(8.5, 13)]; num_repetitions=2,
                                   iteration_mode=:sequential))
    end
end
