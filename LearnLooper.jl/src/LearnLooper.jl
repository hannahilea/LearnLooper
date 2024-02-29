module LearnLooper

using WAV

export learn_loop, launch_gui

include("gui.jl")
using .LearnLooperGUI

struct WAVData
    sample_rate::Any
    samples::Any
end

function WAVData(file)
    y, fs = wavread(file)
    return WAVData(fs, y)
end

"""
    play(input; volume=1, speed) -> nothing
    play(input::WAVData; volume=1, speed) -> nothing

Play `input` scaled to `volume`, at playback `speed` (where e.g. a speed of 2 is
played twice as fast as the original). 

!!! warn
  `input` that is not `WavData` is played back via the OS's text to speech 
  program, and is currently only supported on Mac .
"""
function play(input; volume=1, speed)
    seg = string(input)
    rate = speed * 230
    @debug "$(volume == 0 ? "🎤Pausing" : "👂Playing"): $input"
    Sys.isapple() && run(`say \[\[volm $(volume)\]\] \[\[rate $rate\]\] $seg`)
    return nothing
end

function play(input::WAVData; volume=1, speed)
    @debug "$(volume == 0 ? "🎤Pausing" : "👂Playing WAVData segment")"
    samples = input.samples
    sample_rate = input.sample_rate

    if speed != 1
        @warn "Not yet implemented!"
    end

    #TODO-future: fix cross-platform playback!!
    try
        wavplay(volume .* samples, sample_rate)
    catch err
        @warn "wavplay seems to be broken for your system...." ref = "https://github.com/dancasimiro/WAV.jl/issues/89#issuecomment-719960504" err
    end
    return nothing
end

"""
    pause(input; kwargs...) -> nothing

Pause for the duration it would take to `play(input; kwargs...)`, respecting kwargs
that affect the duration of input playback (e.g., `speed`). For list of `kwargs`,
see [`play`](@ref).
"""
pause(input; kwargs...) = play(input; volume=0, kwargs...)

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

#TODO-future: better way to identify file input (support other WAVData suffixes....)
function preprocess_input(input::String)
    return endswith(input, ".wav") ? WAVData(input) : string.(split(input, " "))
end

function index_for_sec_spans(spans, sample_rate)
    return map(spans) do s
        ind = Int(floor(first(s) * sample_rate)):Int(floor(last(s) * sample_rate))
        return first(ind) == 0 ? (1:last(ind)) : ind
    end
end

_subinput(input, span) = input[span] # TODO-future: use view instead where valid

function _subinput(input::WAVData, span)
    # TODO lol there has to be a better way :) 
    return WAVData(input.sample_rate, view(input.samples, span, :))
end

#####
##### Main entrypoint
#####

"""
    learn_loop(input, spans; num_repetitions=2, iteration_mode=:sequential,
               interrepeat_pause=0, speed=1, dryrun=false) -> nothing

Present the `spans` of `input` as a series of calls ([`play`](@ref)) and responses
[`pause`](@ref)). This is the end-user entrypoint into LearnLooper.jl.

Arguments:
* `input`: TODO-docstring
* `spans`: TODO-docstring
* `num_repetitions`: TODO-docstring
* `iteration_mode`: TODO-docstring
* `interrepeat_pause`: TODO-docstring
* `speed`: TODO-docstring
* `dryrun`: TODO-docstring

#TODO-future: Describe:
- clarify difference between 0 and 1 repetitions; consider "num_playbacks" or similar
- note that non-contiguous `spans` may result in a click in cumulative iteration mode
"""
function learn_loop(input, spans; num_repetitions=2, iteration_mode=:sequential,
                    interrepeat_pause=0, speed=1, dryrun=false)
    #TODO-future: safety-check the iteration_mode, num_repetitions, span v input length
    #TODO-future: if playing text, warn if not mac
    @debug "Welcome to the LearnLooper: prepare to learn by looping!" num_repetitions iteration_mode interrepeat_pause speed dryrun

    input = preprocess_input(input)
    isa(input, WAVData) && (spans = index_for_sec_spans(spans, input.sample_rate))

    #TODO-future: appending to this vector is not good BUT we prob want to refactor 
    # this to be "make a dataframe plan" -> "play dataframe plan" rather than 
    # what it currently is---so okay to do the shady thing for now
    played = []
    for i in eachindex(spans)
        span = collect_span(i, spans; iteration_mode)
        subinput = _subinput(input, span)

        for _ in 1:num_repetitions
            append!(played, [(:play, span), (:pause, span)])
            interrepeat_pause != 0 && push!(played, (:sleep, interrepeat_pause))
            dryrun && continue
            play(subinput; speed)
            pause(subinput; speed)
            sleep(interrepeat_pause)
        end

        # If no repetitions, just play the span and move on---do not pause between spans!!
        # TODO-future: expose as separate param
        if num_repetitions == 0
            push!(played, (:play, span))
            interrepeat_pause != 0 && push!(played, (:sleep, interrepeat_pause))
            dryrun && continue
            play(subinput; speed)
            sleep(interrepeat_pause)
        end
    end
    return played
end

end # module LearnLooper
