module LearnLooper

using WAV

export learn_loop

struct Audio
    sample_rate::Any
    samples::Any
end

function Audio(file)
    y, fs = wavread(file)
    return Audio(fs, y)
end

"""
    play(input; volume_scale=1) -> nothing

Computer plays `span` of `input`. 
Currently only supports Mac playback!
"""
function play(input; volume_scale=1, speed)
    seg = string(input)
    rate = speed * 230
    @debug "$(volume_scale == 0 ? "🎤Pausing" : "👂Playing"): $input"
    Sys.isapple() && run(`say \[\[volm $(volume_scale)\]\] \[\[rate $rate\]\] $seg`)
    return nothing
end

function play(input::Audio; volume_scale=1, speed)
    @debug "$(volume_scale == 0 ? "🎤Pausing" : "👂Playing audio segment")"
    samples = input.samples
    sample_rate = input.sample_rate

    if speed != 1
        @warn "Not yet implemented!"
    end

    #TODO-future: fix cross-platform playback!!
    try
        wavplay(volume_scale .* samples, sample_rate)
    catch err
        @warn "wavplay seems to be broken for your system...." ref = "https://github.com/dancasimiro/WAV.jl/issues/89#issuecomment-719960504" err
    end
    return nothing
end

"""
    pause(input) -> nothing

Computer pauses for duration it would take to play `input`.
"""
pause(input; kwargs...) = play(input; volume_scale=0, kwargs...)

function collect_span(i_span, spans; iteration_mode)
    if iteration_mode == :cumulative
        current_spans = spans[1:i_span]
        return length(current_spans) == 1 ? only(current_spans) :
               collect(Iterators.flatten(spans[1:i_span]))
    end
    if iteration_mode != :sequential
        @warn "`iteration_mode=$mode` is unsupported; falling back to `:sequential` (options: `sequential`, `cumulative`)"
    end
    return spans[i_span]
end

# If input is a single string, split it into words
preprocess_input(input) = input
preprocess_input(input::Number) = string(input)

#TODO-future: better way to identify file input (support other audio suffixes....)
function preprocess_input(input::String)
    return endswith(input, ".wav") ? Audio(input) : string.(split(input, " "))
end

function index_for_sec_spans(spans, sample_rate)
    return map(spans) do s
        ind = Int(floor(first(s) * sample_rate)):Int(floor(last(s) * sample_rate))
        return first(ind) == 0 ? (1:last(ind)) : ind
    end
end

_subinput(input, span) = input[span] # TODO-future: use view instead where valid

function _subinput(input::Audio, span)
    # TODO lol there has to be a better way :) 
    return Audio(input.sample_rate, view(input.samples, span, :))
end

#####
##### Entrypoints
#####

"""
    learn_loop(input, spans; num_repetitions, iteration_mode) -> nothing

#TODO-future: real docstring!
- clarify difference between 0 and 1 repetitions; consider "num_playbacks" or similar
- note that non-contiguous `spans` may result in a click in cumulative iteration mode
"""
function learn_loop(input, spans; num_repetitions=2, iteration_mode=:sequential,
                    interrepeat_pause=0, speed=1)
    #TODO-future: safety-check the iteration_mode, num_repetitions, span v input length
    #TODO-future: if playing text, warn if not mac
    @info "Welcome to the LearnLooper: prepare to learn by looping!" num_repetitions iteration_mode interrepeat_pause

    input = preprocess_input(input)
    isa(input, Audio) && (spans = index_for_sec_spans(spans, input.sample_rate))

    for i in eachindex(spans)
        span = collect_span(i, spans; iteration_mode)
        subinput = _subinput(input, span)

        for _ in 1:num_repetitions
            play(subinput; speed)
            pause(subinput; speed)
            sleep(interrepeat_pause)
        end

        # If no repetitions, just play the span and move on---do not pause between spans!!
        num_repetitions == 0 && play(subinput; speed)
    end
    return nothing
    #TODO: for testing, return vector of spans 
end

end # module LearnLooper
