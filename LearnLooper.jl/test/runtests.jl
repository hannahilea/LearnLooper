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
        # Set up testing 
        output_record = []
        state_callback = state -> push!(output_record, state)

        empty!(output_record)
        learn_loop(collect('a':'z'), [1:2, 3:4]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=2,
                                             iteration_mode=:cumulative,
                                             dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:2), (:pausing, 1:2),
                           (:playing, 1:2), (:pausing, 1:2),
                           (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]),
                           (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]),
                           (:completed, missing)]))

        empty!(output_record)
        learn_loop("A lone sentence is indexed by word", [1:2, 3:4]; state_callback,
                   config=LearnLooper.Config(;
                                             num_repetitions=2, iteration_mode=:cumulative,
                                             dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:2), (:pausing, 1:2), (:playing, 1:2),
                           (:pausing, 1:2), (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]),
                           (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]),
                           (:completed, missing)]))

        empty!(output_record)
        learn_loop(["A vector of phrases", "are indexed", "by phrase"],
                   [1:2, 3:3]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=1,
                                             iteration_mode=:cumulative, dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:2), (:pausing, 1:2), (:playing, [1, 2, 3]),
                           (:pausing, [1, 2, 3]), (:completed, missing)]))

        empty!(output_record)
        learn_loop(pi + 0, [1:4]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=1,
                                             iteration_mode=:cumulative, dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:4), (:pausing, 1:4), (:completed, missing)]))

        empty!(output_record)
        learn_loop(pi + 0, [1:4, 2:3]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=1, pause_for_response=false,
                                             iteration_mode=:cumulative,
                                             interrepeat_pause=0.1, dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:4), (:pausing, 0.1), (:playing, [1, 2, 3, 4, 2, 3]),
                           (:pausing, 0.1), (:completed, missing)]))
    end

    @testset "`learn_loop` from file" begin
        output_record = []
        state_callback = state -> push!(output_record, state)
        f = joinpath(pkgdir(LearnLooper), "README.md")
        learn_loop(read(f, String), [1:2, 3:4]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=2,
                                             iteration_mode=:cumulative, dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:2), (:pausing, 1:2),
                           (:playing, 1:2), (:pausing, 1:2),
                           (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]),
                           (:playing, [1, 2, 3, 4]),
                           (:pausing, [1, 2, 3, 4]), (:completed, missing)]))

        empty!(output_record)
        learn_loop(readlines(f), [1:2, 5:5]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=2,
                                             iteration_mode=:cumulative, dryrun=true))

        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 1:2), (:pausing, 1:2),
                           (:playing, 1:2), (:pausing, 1:2),
                           (:playing, [1, 2, 5]), (:pausing, [1, 2, 5]),
                           (:playing, [1, 2, 5]), (:pausing, [1, 2, 5]),
                           (:completed, missing)]))
    end

    @testset "`learn_loop` from audio file" begin
        using LearnLooper: index_for_sec_spans

        output_record = []
        state_callback = state -> push!(output_record, state)

        fname = joinpath(mktempdir(), "test.wav")
        Fs = 8000
        wavwrite(zeros(3 * Fs, 2), fname; Fs, nbits=0, compression=0)

        # Temporary until we use TimeSpans:
        spans = [(0, 1.2), (2, 3)]
        @test index_for_sec_spans(spans, 1) == [1:1, 2:3]
        learn_loop(fname, [(0.5, 2.5)]; state_callback,
                   config=LearnLooper.Config(; num_repetitions=2,
                                             iteration_mode=:sequential, dryrun=true))
        @test isequal(output_record,
                      map(x -> LearnLooper.PlayStateRecord(x...),
                          [(:playing, 4000:20000), (:pausing, 4000:20000),
                           (:playing, 4000:20000), (:pausing, 4000:20000),
                           (:completed, missing)]))
    end
end
