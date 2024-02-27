using Test
using LearnLooper
using Aqua
using WAV

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
              collect(1:8)

        noncontiguous_spans = [1:4, 9:22]
        @test collect_span(1, noncontiguous_spans; iteration_mode=:cumulative) == 1:4
        @test collect_span(2, noncontiguous_spans; iteration_mode=:cumulative) ==
              collect(Iterators.flatten([1:4, 9:22]))
    end

    @testset "`learn_loop` from raw input" begin
        @test isnothing(learn_loop(collect('a':'z'), [1:2, 3:4]; num_repetitions=2,
                                   iteration_mode=:cumulative))
        @test isnothing(learn_loop("A lone sentence is indexed by word", [1:2, 3:4];
                                   num_repetitions=2, iteration_mode=:cumulative))
        @test isnothing(learn_loop(["A vector of phrases", "are indexed", "by phrase"],
                                   [1:2, 3:3]; num_repetitions=1,
                                   iteration_mode=:cumulative))
        @test isnothing(learn_loop(pi + 0, [1:4]; num_repetitions=1,
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
        using LearnLooper: index_for_sec_spans

        fname = joinpath(mktempdir(), "test.wav")
        Fs = 8000
        wavwrite(zeros(3 * Fs, 2), fname; Fs, nbits=0, compression=0)

        # Temporary until we use TimeSpans:
        spans = [(0, 1.2), (2, 3)]
        @test index_for_sec_spans(spans, 1) == [1:1, 2:3]
        @test isnothing(learn_loop(fname, [(0.5, 2.5)]; num_repetitions=2,
                                   iteration_mode=:sequential))
    end
end
