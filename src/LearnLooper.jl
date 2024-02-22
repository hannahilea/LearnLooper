module LearnLooper

export learn_demo, learnloop

const DEMO_ALPHABET = collect('a':'z')  #TODO-future: make this a loaded audio file

#TODO-future: make this a blob that has more info, e.g. label + timestamp + metadata
const DEMO_SPANS = [1:5, 6:20, 21:26]  # assume non-overlapping and contiguous for the demo spans

"""
    play(input; volume_scale=1) -> nothing

Computer plays `span` of `input`. 
Currently only supports Mac playback!
"""
function play(input; volume_scale=0.8, rate=230)
    seg = string(input)
    @debug "$(volume_scale == 0 ? "🎤Pausing" : "👂Playing"): $seg"
    Sys.isapple() && run(`say \[\[volm $(volume_scale)\]\] \[\[rate $rate\]\] $seg`)
    return nothing
end

"""
    pause(input) -> nothing

Computer pauses for duration it would take to play `input`.
"""
pause(input) = play(input; volume_scale=0)

function compute_learnspan(i_span, spans; iteration_mode)
    if iteration_mode == :cumulative
        current_spans = spans[1:i_span]
        return length(current_spans) == 1 ? only(current_spans) :
               collect(Iterators.flatten(current_spans))
    end
    if iteration_mode != :sequential
        @warn "`iteration_mode=$mode` is unsupported; falling back to `:sequential` (options: `sequential`, `cumulative`)"
    end
    return spans[i_span]
end

# If input is a single string, split it into words
preprocess_input(input) = input
preprocess_input(input::String) = string.(split(input, " "))
preprocess_input(input::Number) = string(input)

#####
##### Entrypoints
#####

"""
    learnloop(input, spans; num_repetitions, iteration_mode) -> nothing

#TODO-future: real docstring!
- clarify difference between 0 and 1 repetitions; consider "num_playbacks" or similar
- note that non-contiguous `spans` may result in a click in cumulative iteration mode
"""
function learnloop(input, spans; num_repetitions, iteration_mode, interrepeat_pause=0)
    #TODO-future: safety-check the iteration_mode, num_repetitions, span v input length
    #TODO-future: if playing text, warn if not mac
    @info "Welcome to the LearnLooper: prepare to learn by looping!" num_repetitions iteration_mode interrepeat_pause

    input = preprocess_input(input)

    for i in eachindex(spans)
        span = compute_learnspan(i, spans; iteration_mode)
        # subinput = view(input, span)  # Make type-based function??
        subinput = input[span]
        for _ in 1:num_repetitions
            play(subinput)
            pause(subinput)
            sleep(interrepeat_pause)
        end

        # If no repetitions, just play the span and move on---do not pause between spans!!
        num_repetitions == 0 && play(subinput)
    end
    return nothing
    #TODO: for testing, return vector of spans 
end

function learn_demo(; num_repetitions=2, iteration_mode=:sequential,
                    spans=DEMO_SPANS, interrepeat_pause=0.1)
    return learnloop(DEMO_ALPHABET, spans; num_repetitions, iteration_mode,
                     interrepeat_pause)
end

end # module LearnLooper
