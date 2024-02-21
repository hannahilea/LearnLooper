module LearnLooper

export learn_demo, learn

const DEMO_SONG = collect('a':'z')  #TODO-future: make this a loaded audio file

#TODO-future: make this a blob that has more info, e.g. label + timestamp + metadata
const DEMO_SEGMENTS = [1:5, 6:20, 21:26]  # assume non-overlapping and contiguous for the demo segments

"""
    play(input, segment; volume_scale=1) -> nothing

Computer plays `segment` of `input`.
"""
function play(input, segment; volume_scale=1)
    seg = input[segment]
    println(volume_scale == 0 ? "🎤Pausing" : "👂Playing", ": ", seg)
    sleep(0.5)
    return nothing
end

function get_learnspan(i_segment, segments; iteration_mode)
    if iteration_mode == :cumulative
        current_segments = segments[1:i_segment]
        return length(current_segments) == 1 ? only(current_segments) : vcat(current_segments)
    end
    if iteration_mode != :sequential
        @warn "`iteration_mode=$mode` is unsupported; falling back to `:sequential` (options: `sequential`, `cumulative`)"
    end
    return segments[i_segment]
end

#####
##### Entrypoints
#####

"""
    pause(input, segment) -> nothing

Computer pauses for duration `segment` of `input`.
"""
pause(input, segment) = play(input, segment; volume_scale=0)

"""
    learn(signal, segments; num_repetitions, iteration_mode) -> nothing

#TODO-future: real docstring!
- clarify difference between 0 and 1 repetitions; consider "num_playbacks" or similar
- note that non-contiguous `segments` may result in a click in cumulative iteration mode
"""
function learn(signal, segments; num_repetitions, iteration_mode, interrepeat_pause)
    #TODO-future: safety-check the iteration_mode, num_repetitions, segment v signal length
    @info "Welcome to the LearnLooper: prepare to learn by looping!" num_repetitions iteration_mode interrepeat_pause
    for i in eachindex(segments)
        learn_span = get_learnspan(i, segments; iteration_mode)
        for _ in 1:num_repetitions
            play(signal, learn_span)
            pause(signal, learn_span)
            sleep(interrepeat_pause)
        end

        # If no repetitions, just play the segment and move on---do not pause between segments!!
        num_repetitions == 0 && play(signal, segment)
    end
    return nothing
end

function learn_demo(; num_repetitions=2, iteration_mode=:sequential,
                    segments=DEMO_SEGMENTS, interrepeat_pause=0.1)
    return learn(DEMO_SONG, segments; num_repetitions, iteration_mode, interrepeat_pause)
end

end # module LearnLooper
