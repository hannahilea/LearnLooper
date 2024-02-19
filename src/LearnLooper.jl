#TODO: set up formatting

module LearnLooper

export learn_demo, learn_song

#TODO-make const
DEMO_SONG = collect('a':'z')  #TODO-future: make this a loaded audio file

#TODO-future: decide how to handle overlapping v non-overlapping
#TODO-future: make this a blob that has more info, e.g. label + timestamp + metadata
const DEMO_SEGMENTS = [1:5, 6:20, 21:26]  # assume non-overlapping and contiguous 

"""
    play(input, segment; volume_scale=1) -> nothing

Computer plays `segment` of `input`.
"""
function play(input, segment; volume_scale=1)
    seg = input[segment]
    println(volume_scale == 0 ? "🎤Pausing" : "👂Playing", ": ", seg)
    return nothing
end

"""
    pause(input, segment) -> nothing

Computer pauses for duration `segment` of `input`.
"""
pause(input, segment) = play(input, segment; volume_scale=0)

#TODO: in docstring, make clear difference between 0 and 1 repetitions; consider "num_playbacks" or similar
function learn_song(signal, segments; num_repetitions, progression_mode)
    #TODO-future: safety-check the progression mode, num_repetitions
    @info "Welcome to the LearnLooper! Prepare to learn by looping!" num_repetitions progression_mode
    for tail_segment in segments
        segment = tail_segment
        if progression_mode == :cumulative 
            segment = first(first(segments)) : last(tail_segment)
        end
        for _ in 1:num_repetitions
            play(signal, segment)
            pause(signal, segment)
        end

        # If no repetitions, just play the segment and move on
        num_repetitions == 0 && play(signal, segment)
    end
    return nothing
end

function learn_demo(; num_repetitions=2, progression_mode=:sequential, segments=DEMO_SEGMENTS)
    return learn_song(DEMO_SONG, segments; num_repetitions, progression_mode)
end

end # module LearnLooper
